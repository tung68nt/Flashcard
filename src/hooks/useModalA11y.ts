import { useEffect } from 'react';

interface UseModalA11yProps {
  isOpen: boolean;
  onClose: () => void;
}

/**
 * Hook hỗ trợ chuẩn tiếp cận W3C Dialog (Modal):
 * 1. Tự động đóng modal khi nhấn phím Escape
 * 2. Khóa cuộn trang nền khi modal đang mở
 */
export function useModalA11y({ isOpen, onClose }: UseModalA11yProps) {
  useEffect(() => {
    if (!isOpen) return;

    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.preventDefault();
        onClose();
      }
    };

    // Khóa cuộn trang
    const originalOverflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';

    window.addEventListener('keydown', handleKeyDown);

    return () => {
      document.body.style.overflow = originalOverflow;
      window.removeEventListener('keydown', handleKeyDown);
    };
  }, [isOpen, onClose]);
}
