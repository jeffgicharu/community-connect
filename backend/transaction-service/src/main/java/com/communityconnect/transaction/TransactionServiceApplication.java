package com.communityconnect.transaction;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;
import org.springframework.statemachine.config.EnableStateMachine;

/**
 * Transaction Service Application
 * 
 * This service handles:
 * - Credit management and balance tracking
 * - Service request workflow
 * - Transaction processing and history
 * - Matching service providers with requesters
 * - State machine for request/transaction flow
 */
@SpringBootApplication
@ConfigurationPropertiesScan
@EnableStateMachine
public class TransactionServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(TransactionServiceApplication.class, args);
    }

}