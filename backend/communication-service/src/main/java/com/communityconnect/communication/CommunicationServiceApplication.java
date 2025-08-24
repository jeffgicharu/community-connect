package com.communityconnect.communication;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;
import org.springframework.web.socket.config.annotation.EnableWebSocket;

/**
 * Communication Service Application
 * 
 * This service handles:
 * - Real-time messaging between users
 * - Email notifications
 * - Push notifications
 * - Message history and chat management
 * - WebSocket connections for real-time features
 */
@SpringBootApplication
@ConfigurationPropertiesScan
@EnableWebSocket
public class CommunicationServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(CommunicationServiceApplication.class, args);
    }

}