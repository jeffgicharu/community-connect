package com.communityconnect.coreservice.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * User entity representing a Community Connect user.
 * 
 * This entity stores core user information including:
 * - Authentication details (email, password hash)
 * - Profile information (name, location, bio)
 * - Verification status (email, phone)
 * - Account status and timestamps
 */
@Entity
@Table(name = "users", indexes = {
    @Index(name = "idx_user_email", columnList = "email", unique = true),
    @Index(name = "idx_user_phone", columnList = "phone_number"),
    @Index(name = "idx_user_location", columnList = "location"),
    @Index(name = "idx_user_created", columnList = "created_at")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EqualsAndHashCode(callSuper = false)
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    @Column(name = "email", nullable = false, unique = true, length = 255)
    @Email(message = "Invalid email format")
    @NotBlank(message = "Email is required")
    private String email;

    @Column(name = "password_hash", nullable = false)
    private String passwordHash;

    @Column(name = "first_name", nullable = false, length = 100)
    @NotBlank(message = "First name is required")
    private String firstName;

    @Column(name = "last_name", nullable = false, length = 100)
    @NotBlank(message = "Last name is required")
    private String lastName;

    @Column(name = "phone_number", length = 20)
    @Pattern(regexp = "^\\+254[0-9]{9}$", message = "Phone number must be in format +254XXXXXXXXX")
    private String phoneNumber;

    @Column(name = "location", nullable = false, length = 200)
    @NotBlank(message = "Location is required")
    private String location;

    @Column(name = "bio", length = 500)
    private String bio;

    @Column(name = "profile_image_url")
    private String profileImageUrl;

    @Column(name = "email_verified", nullable = false)
    @Builder.Default
    private Boolean emailVerified = false;

    @Column(name = "phone_verified", nullable = false)
    @Builder.Default
    private Boolean phoneVerified = false;

    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private Boolean isActive = true;

    @Column(name = "average_rating")
    @Builder.Default
    private Double averageRating = 0.0;

    @Column(name = "total_ratings")
    @Builder.Default
    private Integer totalRatings = 0;

    @Column(name = "services_completed")
    @Builder.Default
    private Integer servicesCompleted = 0;

    @Enumerated(EnumType.STRING)
    @Column(name = "verification_level", nullable = false)
    @Builder.Default
    private VerificationLevel verificationLevel = VerificationLevel.BASIC;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @Column(name = "last_login_at")
    private LocalDateTime lastLoginAt;

    /**
     * Verification levels based on user verification status
     */
    public enum VerificationLevel {
        BASIC,          // Email verified only
        STANDARD,       // Email + Phone verified
        PREMIUM,        // Email + Phone + Address verified
        COMMUNITY       // Vouched for by 3+ verified members
    }

    /**
     * Get the user's full name
     */
    public String getFullName() {
        return firstName + " " + lastName;
    }

    /**
     * Update verification level based on current verification status
     */
    public void updateVerificationLevel() {
        if (emailVerified && phoneVerified) {
            this.verificationLevel = VerificationLevel.STANDARD;
        } else if (emailVerified) {
            this.verificationLevel = VerificationLevel.BASIC;
        }
    }

    /**
     * Check if user can provide services (email verified minimum)
     */
    public boolean canProvideServices() {
        return emailVerified && isActive;
    }

    /**
     * Update average rating with new rating
     */
    public void updateRating(int newRating) {
        if (newRating < 1 || newRating > 5) {
            throw new IllegalArgumentException("Rating must be between 1 and 5");
        }
        
        double currentTotal = averageRating * totalRatings;
        totalRatings++;
        averageRating = (currentTotal + newRating) / totalRatings;
    }
}