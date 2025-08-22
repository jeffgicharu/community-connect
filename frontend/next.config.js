/** @type {import('next').NextConfig} */
const nextConfig = {
  // Enable experimental features
  experimental: {
    turbo: {
      // Turbopack configuration
      resolveAlias: {
        '@': './app',
        '@/components': './components',
        '@/lib': './lib',
        '@/hooks': './hooks',
        '@/store': './store',
        '@/types': './types',
        '@/services': './services',
        '@/styles': './styles'
      }
    }
  },

  // Environment variables
  env: {
    CUSTOM_KEY: process.env.CUSTOM_KEY,
  },

  // Image domains for external images
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'res.cloudinary.com',
        pathname: '**',
      },
      {
        protocol: 'https',
        hostname: 'cloudinary.com',
        pathname: '**',
      },
      {
        protocol: 'https',
        hostname: 'avatars.githubusercontent.com',
        pathname: '**',
      },
      {
        protocol: 'https',
        hostname: 'lh3.googleusercontent.com',
        pathname: '**',
      }
    ],
    // Image optimization
    deviceSizes: [640, 750, 828, 1080, 1200, 1920, 2048, 3840],
    imageSizes: [16, 32, 48, 64, 96, 128, 256, 384],
  },

  // API rewrites for development
  async rewrites() {
    return [
      {
        source: '/api/v1/core/:path*',
        destination: process.env.NEXT_PUBLIC_CORE_SERVICE_URL 
          ? `${process.env.NEXT_PUBLIC_CORE_SERVICE_URL}/:path*` 
          : 'http://localhost:8081/api/v1/:path*'
      },
      {
        source: '/api/v1/transaction/:path*',
        destination: process.env.NEXT_PUBLIC_TRANSACTION_SERVICE_URL 
          ? `${process.env.NEXT_PUBLIC_TRANSACTION_SERVICE_URL}/:path*` 
          : 'http://localhost:8082/api/v1/:path*'
      },
      {
        source: '/api/v1/communication/:path*',
        destination: process.env.NEXT_PUBLIC_COMMUNICATION_SERVICE_URL 
          ? `${process.env.NEXT_PUBLIC_COMMUNICATION_SERVICE_URL}/:path*` 
          : 'http://localhost:8083/api/v1/:path*'
      }
    ];
  },

  // CORS headers for API routes
  async headers() {
    return [
      {
        source: '/api/:path*',
        headers: [
          { key: 'Access-Control-Allow-Credentials', value: 'true' },
          { key: 'Access-Control-Allow-Origin', value: '*' },
          { key: 'Access-Control-Allow-Methods', value: 'GET,OPTIONS,PATCH,DELETE,POST,PUT' },
          { key: 'Access-Control-Allow-Headers', value: 'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version, Authorization' },
        ]
      }
    ];
  },

  // Standalone output for Docker
  output: process.env.NODE_ENV === 'production' ? 'standalone' : undefined,

  // Webpack configuration
  webpack: (config, { buildId, dev, isServer, defaultLoaders, webpack }) => {
    // Custom webpack configurations
    if (!isServer) {
      config.resolve.fallback = {
        ...config.resolve.fallback,
        fs: false,
        net: false,
        tls: false,
      };
    }

    return config;
  },

  // TypeScript configuration
  typescript: {
    // !! WARN !!
    // Dangerously allow production builds to successfully complete even if
    // your project has TypeScript errors.
    ignoreBuildErrors: false,
  },

  // ESLint configuration
  eslint: {
    // Warning: This allows production builds to successfully complete even if
    // your project has ESLint errors.
    ignoreDuringBuilds: false,
  },

  // Disable x-powered-by header
  poweredByHeader: false,

  // Compress responses
  compress: true,

  // Trailing slash configuration
  trailingSlash: false,

  // React strict mode
  reactStrictMode: true,

  // SWC minification
  swcMinify: true,

  // Bundle analyzer (enable with ANALYZE=true)
  ...(process.env.ANALYZE === 'true' && {
    experimental: {
      ...nextConfig.experimental,
      bundleAnalyzer: {
        enabled: true,
      },
    },
  }),
};

module.exports = nextConfig;