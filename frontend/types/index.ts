// TypeScript Type Definitions
// Shared types and interfaces for Community Connect

// Type definitions will be added here as they are developed
// Example exports:
// export type { User } from './user';
// export type { Service } from './service';

// Common utility types
export interface PaginationParams {
  page: number;
  limit: number;
}

export interface ApiError {
  message: string;
  code: string;
  details?: unknown;
}

export interface FilterParams {
  search?: string;
  category?: string;
  location?: string;
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
}