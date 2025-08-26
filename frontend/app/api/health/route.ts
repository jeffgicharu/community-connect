import { NextResponse } from 'next/server';

export async function GET() {
  try {
    // Basic health check
    return NextResponse.json(
      {
        status: 'healthy',
        timestamp: new Date().toISOString(),
        service: 'Community Connect Frontend',
        version: process.env.npm_package_version || '1.0.0',
      },
      { status: 200 }
    );
  } catch (error) {
    return NextResponse.json(
      {
        status: 'unhealthy',
        timestamp: new Date().toISOString(),
        error: error instanceof Error ? error.message : 'Unknown error',
      },
      { status: 500 }
    );
  }
}

export async function HEAD() {
  // Support HEAD requests for health checks
  return new Response(null, { status: 200 });
}