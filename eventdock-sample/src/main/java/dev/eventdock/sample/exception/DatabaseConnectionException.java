package dev.eventdock.sample.exception;

public class DatabaseConnectionException extends RuntimeException {
    public DatabaseConnectionException(String message) {
        super(message);
    }
}
