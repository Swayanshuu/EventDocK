package dev.eventdock.starter.reporting;

import dev.eventdock.starter.config.EventDockProperties;
import dev.eventdock.starter.model.DiagnosticEvent;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

import static org.assertj.core.api.Assertions.assertThat;

class AsyncEventQueueTest {

    @Test
    @DisplayName("Should buffer events and flush them to batch consumer without blocking")
    void testEnqueueAndFlush() throws InterruptedException {
        EventDockProperties.QueueProperties queueProps = new EventDockProperties.QueueProperties();
        queueProps.setCapacity(50);
        queueProps.setBatchSize(5);
        queueProps.setFlushIntervalMs(100);

        List<DiagnosticEvent> consumed = new ArrayList<>();
        CountDownLatch latch = new CountDownLatch(5);

        try (AsyncEventQueue queue = new AsyncEventQueue(queueProps, batch -> {
            synchronized (consumed) {
                consumed.addAll(batch);
                batch.forEach(e -> latch.countDown());
            }
        })) {
            for (int i = 0; i < 5; i++) {
                boolean accepted = queue.enqueue(DiagnosticEvent.builder().requestId("req-" + i).build());
                assertThat(accepted).isTrue();
            }

            boolean completed = latch.await(2, TimeUnit.SECONDS);
            assertThat(completed).isTrue();

            synchronized (consumed) {
                assertThat(consumed).hasSize(5);
            }
        }
    }

    @Test
    @DisplayName("Should drop events gracefully when bounded queue capacity is exceeded")
    void testQueueCapacityOverflow() {
        EventDockProperties.QueueProperties queueProps = new EventDockProperties.QueueProperties();
        queueProps.setCapacity(3);
        queueProps.setBatchSize(100); // won't auto-flush on batchSize
        queueProps.setFlushIntervalMs(10000); // won't flush immediately

        try (AsyncEventQueue queue = new AsyncEventQueue(queueProps, batch -> {})) {
            // Fill capacity
            assertThat(queue.enqueue(DiagnosticEvent.builder().requestId("1").build())).isTrue();
            assertThat(queue.enqueue(DiagnosticEvent.builder().requestId("2").build())).isTrue();
            assertThat(queue.enqueue(DiagnosticEvent.builder().requestId("3").build())).isTrue();

            // Next one must be dropped safely without exception
            assertThat(queue.enqueue(DiagnosticEvent.builder().requestId("4").build())).isFalse();
            assertThat(queue.getDroppedEventsCount()).isEqualTo(1);
        }
    }
}
