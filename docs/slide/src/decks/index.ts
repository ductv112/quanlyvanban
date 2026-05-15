import type { DeckMeta } from '@/presenter/SlideDeck';
import { daoTao } from './dao-tao';

export const decks: DeckMeta[] = [daoTao];

export const decksBySlug: Record<string, DeckMeta> = {
  'dao-tao': daoTao,
};
