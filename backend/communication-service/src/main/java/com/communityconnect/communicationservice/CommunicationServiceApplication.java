package com.communityconnect.communicationservice;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.openfeign.EnableFeignClients;

/**
 * Community Connect Communication Service Application
 * 
 * This microservice handles:
 * - Real-time messaging between users
 * - Push notifications and email notifications
 * - WebSocket connections for chat
 * - Message history and conversation management
 * - System notifications for service events
 * 
 * @author Community Connect Team
 * @version 1.0.0
 */
@SpringBootApplication
@EnableFeignClients
public class CommunicationServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(CommunicationServiceApplication.class, args);
    }
}