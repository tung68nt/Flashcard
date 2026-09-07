import React from 'react';

export function getPosClass(pos?: string): string {
  if (!pos) return 'pos-chip pos-chip-default';
  const p = pos.toLowerCase();
  if (p.includes('noun') || p === 'n') return 'pos-chip pos-chip-noun';
  if (p.includes('verb') || p === 'v') return 'pos-chip pos-chip-verb';
  if (p.includes('adj') || p.includes('tính')) return 'pos-chip pos-chip-adj';
  if (p.includes('adv') || p.includes('trạng')) return 'pos-chip pos-chip-adv';
  if (p.includes('idiom') || p.includes('thành ngữ')) return 'pos-chip pos-chip-idiom';
  if (p.includes('grammar') || p.includes('cấu trúc') || p.includes('ngữ pháp')) return 'pos-chip pos-chip-grammar';
  return 'pos-chip pos-chip-default';
}

export const PosChip: React.FC<{ pos?: string }> = ({ pos }) => {
  if (!pos) return null;
  return <span className={getPosClass(pos)}>{pos}</span>;
};
