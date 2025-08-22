// Community Connect Type Definitions

// User Types
export interface User {
  id: string
  email: string
  firstName: string
  lastName: string
  phoneNumber?: string
  location: string
  bio?: string
  profileImageUrl?: string
  emailVerified: boolean
  phoneVerified: boolean
  isActive: boolean
  averageRating: number
  totalRatings: number
  servicesCompleted: number
  verificationLevel: VerificationLevel
  createdAt: string
  updatedAt: string
  lastLoginAt?: string
}

export enum VerificationLevel {
  BASIC = 'BASIC',
  STANDARD = 'STANDARD', 
  PREMIUM = 'PREMIUM',
  COMMUNITY = 'COMMUNITY'
}

// Service Types
export interface Service {
  id: string
  userId: string
  title: string
  description: string
  category: ServiceCategory
  timeRequired: number
  isActive: boolean
  imageUrls?: string[]
  tags?: string[]
  user?: User
  reviews?: Review[]
  createdAt: string
  updatedAt: string
}

export enum ServiceCategory {
  EDUCATION = 'EDUCATION',
  HOME_SERVICES = 'HOME_SERVICES',
  PERSONAL_CARE = 'PERSONAL_CARE',
  PROFESSIONAL = 'PROFESSIONAL',
  TRANSPORTATION = 'TRANSPORTATION',
  FOOD_COOKING = 'FOOD_COOKING',
  ARTS_CRAFTS = 'ARTS_CRAFTS',
  GENERAL_HELP = 'GENERAL_HELP'
}

// Transaction Types
export interface CreditAccount {
  userId: string
  balance: number
  lastUpdated: string
  version: number
}

export interface ServiceRequest {
  id: string
  serviceId: string
  requesterId: string
  providerId?: string
  status: RequestStatus
  description: string
  scheduledFor?: string
  location?: string
  estimatedDuration: number
  actualDuration?: number
  requestedAt: string
  expiresAt: string
  completedAt?: string
  service?: Service
  requester?: User
  provider?: User
  transaction?: Transaction
}

export enum RequestStatus {
  PENDING = 'PENDING',
  ACCEPTED = 'ACCEPTED',
  IN_PROGRESS = 'IN_PROGRESS',
  COMPLETED = 'COMPLETED',
  CANCELLED = 'CANCELLED',
  EXPIRED = 'EXPIRED'
}

export interface Transaction {
  id: string
  requestId: string
  credits: number
  completedAt: string
  rating?: number
  review?: string
  request?: ServiceRequest
}

// Communication Types
export interface Message {
  id: string
  conversationId: string
  senderId: string
  recipientId: string
  message: string
  messageType: MessageType
  timestamp: string
  read: boolean
  sender?: User
}

export enum MessageType {
  TEXT = 'TEXT',
  SYSTEM = 'SYSTEM',
  NOTIFICATION = 'NOTIFICATION'
}

export interface Conversation {
  id: string
  participants: string[]
  lastMessage?: Message
  lastActivity: string
  unreadCount: number
}

export interface Notification {
  id: string
  userId: string
  type: NotificationType
  data: Record<string, any>
  createdAt: string
  sent: boolean
  sentAt?: string
  read: boolean
  readAt?: string
}

export enum NotificationType {
  SERVICE_REQUEST = 'SERVICE_REQUEST',
  SERVICE_ACCEPTED = 'SERVICE_ACCEPTED', 
  SERVICE_COMPLETED = 'SERVICE_COMPLETED',
  MESSAGE_RECEIVED = 'MESSAGE_RECEIVED',
  CREDIT_RECEIVED = 'CREDIT_RECEIVED'
}

// Review Types
export interface Review {
  id: string
  serviceId: string
  reviewerId: string
  providerId: string
  rating: number
  comment?: string
  transactionId: string
  createdAt: string
  reviewer?: User
  service?: Service
}

// API Response Types
export interface ApiResponse<T> {
  data: T
  message?: string
  success: boolean
}

export interface PaginatedResponse<T> {
  data: T[]
  pagination: {
    page: number
    limit: number
    total: number
    totalPages: number
    hasNext: boolean
    hasPrevious: boolean
  }
}

export interface ApiError {
  message: string
  code: string
  details?: Record<string, any>
}

// Form Types
export interface LoginForm {
  email: string
  password: string
  rememberMe?: boolean
}

export interface RegisterForm {
  email: string
  password: string
  confirmPassword: string
  firstName: string
  lastName: string
  phoneNumber?: string
  location: string
  bio?: string
  termsAccepted: boolean
}

export interface ServiceForm {
  title: string
  description: string
  category: ServiceCategory
  timeRequired: number
  tags?: string[]
  images?: File[]
}

export interface RequestForm {
  serviceId: string
  description: string
  scheduledFor?: string
  location?: string
  estimatedDuration: number
}

// Search and Filter Types
export interface SearchFilters {
  query?: string
  category?: ServiceCategory
  location?: string
  minRating?: number
  maxDistance?: number
  availability?: string
  priceRange?: [number, number]
  sortBy?: 'relevance' | 'rating' | 'distance' | 'newest'
  sortOrder?: 'asc' | 'desc'
}

export interface SearchResult {
  services: Service[]
  users: User[]
  total: number
  filters: SearchFilters
}

// UI State Types
export interface LoadingState {
  isLoading: boolean
  error?: string | null
}

export interface ModalState {
  isOpen: boolean
  type?: string
  data?: any
}

// WebSocket Types
export interface WebSocketMessage {
  type: string
  payload: any
  timestamp: string
}

// NextAuth Types (extending default)
declare module 'next-auth' {
  interface Session {
    user: {
      id: string
      email: string
      name: string
      image?: string
      accessToken?: string
    }
    accessToken?: string
    refreshToken?: string
  }

  interface User {
    id: string
    email: string
    name: string
    image?: string
    accessToken?: string
  }
}

declare module 'next-auth/jwt' {
  interface JWT {
    accessToken?: string
    refreshToken?: string
    accessTokenExpires?: number
  }
}