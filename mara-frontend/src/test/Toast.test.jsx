import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

// ── Toast ─────────────────────────────────────────────────────────────────────

import { ToastProvider, useToast } from '../components/Toast';

function TestConsumer({ type = 'success', message = 'Test message' }) {
    const { addToast } = useToast();
    return (
        <button onClick={() => addToast(message, type)}>
            Show Toast
        </button>
    );
}

describe('Toast system', () => {
    it('shows a toast message when addToast is called', async () => {
        const user = userEvent.setup();
        render(
            <ToastProvider>
                <TestConsumer message="Enregistrement réussi !" type="success" />
            </ToastProvider>
        );

        await user.click(screen.getByRole('button', { name: /show toast/i }));
        expect(screen.getByText('Enregistrement réussi !')).toBeInTheDocument();
    });

    it('shows multiple toasts simultaneously', async () => {
        const user = userEvent.setup();

        function MultiConsumer() {
            const { addToast } = useToast();
            return (
                <>
                    <button onClick={() => addToast('Toast alpha', 'success')}>Btn A</button>
                    <button onClick={() => addToast('Toast bêta', 'error')}>Btn B</button>
                </>
            );
        }

        render(
            <ToastProvider>
                <MultiConsumer />
            </ToastProvider>
        );

        await user.click(screen.getByRole('button', { name: 'Btn A' }));
        await user.click(screen.getByRole('button', { name: 'Btn B' }));

        expect(screen.getByText('Toast alpha')).toBeInTheDocument();
        expect(screen.getByText('Toast bêta')).toBeInTheDocument();
    });
});
