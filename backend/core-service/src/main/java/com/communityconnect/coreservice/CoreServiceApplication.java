package com.communityconnect.coreservice;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.openfeign.EnableFeignClients;

/**
 * Community Connect Core Service Application
 * 
 * This microservice handles:
 * - User management and authentication
 * - User profiles and verification
 * - Service listings and search
 * - Image management via Cloudinary
 * 
 * @author Community Connect Team
 * @version 1.0.0
 */
@SpringBootApplication
@EnableFeignClients
public class CoreServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(CoreServiceApplication.class, args);
    }
}