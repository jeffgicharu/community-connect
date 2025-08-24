package com.communityconnect.core;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

/**
 * Core Service Application
 * 
 * This service handles:
 * - User management and authentication
 * - User profiles and verification
 * - Service listings (CRUD operations)
 * - Search functionality
 * - File upload (profile pictures, service images)
 */
@SpringBootApplication
@ConfigurationPropertiesScan
public class CoreServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(CoreServiceApplication.class, args);
    }

}