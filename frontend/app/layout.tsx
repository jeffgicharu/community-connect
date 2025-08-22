import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'
import { Providers } from './providers'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: {
    default: 'Community Connect',
    template: '%s | Community Connect'
  },
  description: 'A hyperlocal service exchange platform that connects neighbors through a time-banking system',
  keywords: ['community', 'services', 'time banking', 'local', 'neighbors', 'skills', 'exchange'],
  authors: [{ name: 'Community Connect Team' }],
  creator: 'Community Connect',
  publisher: 'Community Connect',
  formatDetection: {
    email: false,
    address: false,
    telephone: false,
  },
  metadataBase: new URL(process.env.NEXTAUTH_URL || 'http://localhost:3000'),
  openGraph: {
    type: 'website',
    locale: 'en_US',
    url: process.env.NEXTAUTH_URL || 'http://localhost:3000',
    title: 'Community Connect - Local Service Exchange',
    description: 'Connect with your neighbors and exchange services using time as currency',
    siteName: 'Community Connect',
    images: [
      {
        url: '/images/og-image.jpg',
        width: 1200,
        height: 630,
        alt: 'Community Connect - Local Service Exchange',
      },
    ],
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Community Connect - Local Service Exchange',
    description: 'Connect with your neighbors and exchange services using time as currency',
    images: ['/images/og-image.jpg'],
    creator: '@communityconnect',
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      'max-video-preview': -1,
      'max-image-preview': 'large',
      'max-snippet': -1,
    },
  },
  verification: {
    google: process.env.GOOGLE_SITE_VERIFICATION,
  },
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className={inter.className}>
        <Providers>
          <div className="min-h-screen bg-gray-50">
            {children}
          </div>
        </Providers>
      </body>
    </html>
  )
}