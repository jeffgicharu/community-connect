// Community Connect Communication Service MongoDB Initialization
// This script sets up the basic database structure for the communication service

// Switch to the communication service database
db = db.getSiblingDB('communication_service');

// Create collections with validation
db.createCollection('messages', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['conversationId', 'senderId', 'recipientId', 'message', 'timestamp'],
      properties: {
        conversationId: {
          bsonType: 'string',
          description: 'Conversation ID is required and must be a string'
        },
        senderId: {
          bsonType: 'string',
          description: 'Sender ID is required and must be a string'
        },
        recipientId: {
          bsonType: 'string',
          description: 'Recipient ID is required and must be a string'
        },
        message: {
          bsonType: 'string',
          maxLength: 2000,
          description: 'Message content is required and must be a string with max 2000 characters'
        },
        timestamp: {
          bsonType: 'date',
          description: 'Timestamp is required and must be a date'
        },
        read: {
          bsonType: 'bool',
          description: 'Read status must be a boolean'
        },
        messageType: {
          bsonType: 'string',
          enum: ['text', 'system', 'notification'],
          description: 'Message type must be one of: text, system, notification'
        }
      }
    }
  }
});

db.createCollection('notifications', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['userId', 'type', 'data', 'createdAt'],
      properties: {
        userId: {
          bsonType: 'string',
          description: 'User ID is required and must be a string'
        },
        type: {
          bsonType: 'string',
          enum: ['service_request', 'service_accepted', 'service_completed', 'message_received', 'credit_received'],
          description: 'Notification type is required'
        },
        data: {
          bsonType: 'object',
          description: 'Notification data is required'
        },
        createdAt: {
          bsonType: 'date',
          description: 'Created timestamp is required'
        },
        sent: {
          bsonType: 'bool',
          description: 'Sent status must be a boolean'
        },
        sentAt: {
          bsonType: 'date',
          description: 'Sent timestamp must be a date'
        },
        read: {
          bsonType: 'bool',
          description: 'Read status must be a boolean'
        },
        readAt: {
          bsonType: 'date',
          description: 'Read timestamp must be a date'
        }
      }
    }
  }
});

// Create indexes for better query performance
db.messages.createIndex({ 'conversationId': 1, 'timestamp': -1 });
db.messages.createIndex({ 'senderId': 1, 'timestamp': -1 });
db.messages.createIndex({ 'recipientId': 1, 'read': 1 });
db.messages.createIndex({ 'timestamp': 1 }, { expireAfterSeconds: 7776000 }); // 90 days TTL

db.notifications.createIndex({ 'userId': 1, 'createdAt': -1 });
db.notifications.createIndex({ 'type': 1, 'createdAt': -1 });
db.notifications.createIndex({ 'sent': 1, 'createdAt': 1 });
db.notifications.createIndex({ 'createdAt': 1 }, { expireAfterSeconds: 2592000 }); // 30 days TTL

// Insert initial system data
db.messages.insertOne({
  conversationId: 'system-init',
  senderId: 'system',
  recipientId: 'system',
  message: 'Communication service database initialized successfully',
  messageType: 'system',
  timestamp: new Date(),
  read: true
});

print('Community Connect Communication Service database initialized successfully!');
print('Collections created: messages, notifications');
print('Indexes created for optimal query performance');
print('TTL indexes set: messages (90 days), notifications (30 days)');