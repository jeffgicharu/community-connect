package com.communityconnect.transactionservice;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.openfeign.EnableFeignClients;

/**
 * Community Connect Transaction Service Application
 * 
 * This microservice handles:
 * - Credit management and balance tracking
 * - Service request processing
 * - Transaction lifecycle management
 * - Credit transfer operations
 * - Matching service providers with requesters
 * 
 * @author Community Connect Team
 * @version 1.0.0
 */
@SpringBootApplication
@EnableFeignClients
public class TransactionServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(TransactionServiceApplication.class, args);
    }
}