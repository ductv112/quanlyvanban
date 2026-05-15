import { Routes, Route, useParams, Navigate } from 'react-router-dom';
import { Home } from '@/pages/Home';
import { SlideDeck } from '@/presenter/SlideDeck';
import { decksBySlug } from '@/decks';

function DeckRoute() {
  const { slug } = useParams();
  const deck = slug ? decksBySlug[slug] : undefined;
  if (!deck) return <Navigate to="/" replace />;
  return <SlideDeck deck={deck} />;
}

export default function App() {
  return (
    <Routes>
      <Route path="/" element={<Home />} />
      <Route path="/:slug" element={<DeckRoute />} />
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
