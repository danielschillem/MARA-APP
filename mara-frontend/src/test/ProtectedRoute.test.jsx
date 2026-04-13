import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';

// ── ProtectedRoute ────────────────────────────────────────────────────────────
// Mock AuthContext to control user state

vi.mock('../contexts/AuthContext', () => ({
    useAuth: vi.fn(),
}));

import ProtectedRoute from '../components/ProtectedRoute';
import { useAuth } from '../contexts/AuthContext';

describe('ProtectedRoute', () => {
    it('renders children when user is authenticated', () => {
        useAuth.mockReturnValue({ user: { id: 1, name: 'Alice', role: 'conseiller' } });

        render(
            <MemoryRouter>
                <ProtectedRoute>
                    <div data-testid="protected-content">Secret</div>
                </ProtectedRoute>
            </MemoryRouter>
        );

        expect(screen.getByTestId('protected-content')).toBeInTheDocument();
        expect(screen.getByText('Secret')).toBeInTheDocument();
    });

    it('redirects to /login when user is not authenticated', () => {
        useAuth.mockReturnValue({ user: null });

        render(
            <MemoryRouter initialEntries={['/dashboard']}>
                <ProtectedRoute>
                    <div data-testid="protected-content">Secret</div>
                </ProtectedRoute>
            </MemoryRouter>
        );

        // Should NOT render the protected content
        expect(screen.queryByTestId('protected-content')).not.toBeInTheDocument();
    });
});
