# Community Connect

A hyperlocal service exchange platform that connects neighbors through a time-banking system, where people exchange services using time as currency.

## What is Community Connect?

Community Connect enables neighbors to help each other by offering and requesting services within their local communities. Instead of money, people exchange hours - **one hour of your time equals one hour of someone else's time**, regardless of the service provided.

### How It Works

1. **Jane** spends 2 hours teaching math to **Peter's** child
2. Jane earns 2 time credits
3. Jane uses 1 credit to get 1 hour of plumbing help from **Samuel**
4. Jane still has 1 credit for future use

### Core Values

- **Equality**: A doctor's hour equals a cleaner's hour - promotes dignity
- **Accessibility**: No money required to participate
- **Community Building**: Encourages neighbor-to-neighbor connections
- **Skill Valorization**: Every skill has value

## Architecture

Community Connect is built as a microservices architecture with a modern tech stack:

### Backend (3 Microservices)
- **Core Service** - User management, authentication, and service listings
- **Transaction Service** - Credit management, service requests, and transaction processing  
- **Communication Service** - Real-time messaging, notifications, and email

### Frontend
- **Next.js Application** - Server-side rendered React app with responsive design

### Technology Stack

#### Backend
- Java 17 with Spring Boot 3.x
- PostgreSQL (primary database)
- MongoDB (messages)
- Redis (caching)
- Docker containerization

#### Frontend
- Next.js 14 (App Router)
- React 18 with TypeScript
- Material-UI v5
- Apollo Client for GraphQL

#### Infrastructure
- Railway.app/Render (backend services)
- Vercel (frontend)
- Neon.tech (PostgreSQL)
- MongoDB Atlas
- Upstash (Redis)

## Quick Start

### Prerequisites
- Java 17+
- Node.js 18+
- Docker & Docker Compose
- Git

### Local Development Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd community-connect
   ```

2. **Start backend services**
   ```bash
   cd backend
   docker-compose up -d
   # Individual service setup instructions in each service directory
   ```

3. **Start frontend**
   ```bash
   cd frontend
   npm install
   npm run dev
   ```

4. **Access the application**
   - Frontend: http://localhost:3000
   - Core Service API: http://localhost:8081
   - Transaction Service API: http://localhost:8082
   - Communication Service API: http://localhost:8083

### Project Structure

```
community-connect/
├── backend/                 # Microservices
│   ├── core-service/       # User management & service listings
│   ├── transaction-service/# Credit system & transactions
│   ├── communication-service/ # Messaging & notifications
│   └── shared/             # Shared utilities
├── frontend/               # Next.js application
├── infrastructure/         # Docker & deployment configs
├── scripts/               # Automation scripts
└── documentation/         # Design docs (not tracked in git)
```

## Service Categories

- **Education**: Tutoring, language lessons, computer training
- **Home Services**: Cleaning, repairs, painting, plumbing
- **Personal Care**: Hair styling, elderly care, childcare
- **Professional**: Accounting basics, CV writing, phone repair
- **Transportation**: School runs, market trips, errands

## Development

### Running Tests
```bash
# Backend tests
cd backend/[service-name]
./mvnw test

# Frontend tests
cd frontend
npm test
```

### Building for Production
```bash
# Backend
cd backend/[service-name]
./mvnw clean package

# Frontend
cd frontend
npm run build
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Roadmap

### Phase 1 (MVP) - Completed
- [ ] User registration and authentication
- [ ] Basic service listings and search
- [ ] Simple credit system
- [ ] In-app messaging
- [ ] Basic rating system

### Phase 2
- [ ] Advanced scheduling
- [ ] Mobile app
- [ ] Multi-language support (Kiswahili)
- [ ] Group services
- [ ] Community boards

### Phase 3
- [ ] AI-powered matching
- [ ] Voice interface
- [ ] Business accounts
- [ ] API for third-party integrations

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support, email support@communityconnect.ke or join our community discussions.

---

**Built with ❤️ for Kenyan communities**