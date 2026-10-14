package dev.eventdock.starter.reporting;

import dev.eventdock.starter.config.EventDockProperties;
import dev.eventdock.starter.model.DiagnosticEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicLong;
import java.util.function.Consumer;

/**
 * Bounded asynchronous queue that buffers diagnostic events and dispatches them in batches.
 * Ensures the host application's request thread is never blocked or compromised.
 */
public class AsyncEventQueue implements AutoCloseable {

    private static final Logger log = LoggerFactory.getLogger(AsyncEventQueue.class);

    private final BlockingQueue<DiagnosticEvent> queue;
    private final Consumer<List<DiagnosticEvent>> batchConsumer;
    private final int batchSize;
    private final ScheduledExecutorService scheduler;
    private final AtomicLong droppedEvents = new AtomicLong(0);
    private final AtomicLong enqueuedEvents = new AtomicLong(0);
    private volatile boolean running = true;

    public AsyncEventQueue(EventDockProperties.QueueProperties queueProps,
                           Consumer<List<DiagnosticEvent>> batchConsumer) {
        int capacity = (queueProps != null && queueProps.getCapacity() > 0)
                ? queueProps.getCapacity()
                : 500;
        this.batchSize = (queueProps != null && queueProps.getBatchSize() > 0)
                ? queueProps.getBatchSize()
                : 25;
        long flushIntervalMs = (queueProps != null && queueProps.getFlushIntervalMs() > 0)
                ? queueProps.getFlushIntervalMs()
                : 1000;

        this.queue = new ArrayBlockingQueue<>(capacity);
        this.batchConsumer = batchConsumer;

        this.scheduler = Executors.newSingleThreadScheduledExecutor(r -> {
            Thread t = new Thread(r, "eventdock-queue-worker");
            t.setDaemon(true);
            return t;
        });

        this.scheduler.scheduleWithFixedDelay(
                this::flushBatch,
                flushIntervalMs,
                flushIntervalMs,
                TimeUnit.MILLISECONDS
        );
    }

    /**
     * Non-blocking attempt to enqueue an event.
     */
    public boolean enqueue(DiagnosticEvent event) {
        if (!running || event == null) {
            return false;
        }

        boolean accepted = queue.offer(event);
        if (accepted) {
            enqueuedEvents.incrementAndGet();
            if (queue.size() >= batchSize) {
                scheduler.execute(this::flushBatch);
            }
            return true;
        } else {
            long drops = droppedEvents.incrementAndGet();
            if (drops % 100 == 1) {
                log.warn("EventDock queue capacity reached. Dropped {} diagnostic events so far to protect host app.", drops);
            }
            return false;
        }
    }

    private void flushBatch() {
        if (queue.isEmpty()) {
            return;
        }

        List<DiagnosticEvent> batch = new ArrayList<>(batchSize);
        queue.drainTo(batch, batchSize);

        if (!batch.isEmpty() && batchConsumer != null) {
            try {
                batchConsumer.accept(batch);
            } catch (Exception e) {
                log.debug("Error while dispatching EventDock batch of {} events: {}", batch.size(), e.getMessage());
            }
        }
    }

    public long getDroppedEventsCount() {
        return droppedEvents.get();
    }

    public long getEnqueuedEventsCount() {
        return enqueuedEvents.get();
    }

    public int getCurrentQueueSize() {
        return queue.size();
    }

    @Override
    public void close() {
        running = false;
        try {
            // Drain remaining events once before shutdown
            flushBatch();
            scheduler.shutdown();
            if (!scheduler.awaitTermination(2, TimeUnit.SECONDS)) {
                scheduler.shutdownNow();
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            scheduler.shutdownNow();
        }
    }
}
