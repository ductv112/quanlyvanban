/**
 * tests/fixtures/docs.ts — Doc fixture id ranges
 *
 * Đồng bộ với database/seed/003_test_fixtures.sql.
 *
 * incoming_docs trạng thái derive từ flags:
 *   new: approved=false, no user_incoming_docs
 *   distributed: approved=true, user_incoming_docs.is_read=false
 *   processing: approved=true, user_incoming_docs.is_read=true
 *   completed: approved=true, archive_status=true
 *   rejected: approved=false, rejected_by IS NOT NULL
 *
 * outgoing_docs status enum: draft / reviewing / released / sent / completed / rejected
 * drafting_docs status enum: draft / reviewing / approved / released / rejected
 * handling_docs status smallint: 0=draft, 1=active, 4=completed
 */

export const TEST_DOCS = {
  incoming: {
    new: { id: 90001, notation: 'TEST/VBD-NEW', state: 'new' as const },
    distributed: { id: 90002, notation: 'TEST/VBD-DIST', state: 'distributed' as const },
    processing: { id: 90003, notation: 'TEST/VBD-PROC', state: 'processing' as const },
    completed: { id: 90004, notation: 'TEST/VBD-DONE', state: 'completed' as const },
    rejected: { id: 90005, notation: 'TEST/VBD-RJCT', state: 'rejected' as const },
  },
  outgoing: {
    released: { id: 90001, notation: 'TEST/VBD-OUT-1', status: 'released' as const },
    sent: { id: 90002, notation: 'TEST/VBD-OUT-2', status: 'sent' as const },
    cross_unit: { id: 90003, notation: 'TEST/VBD-OUT-3', status: 'released' as const },
  },
  drafting: {
    pending: { id: 90001, notation: 'TEST/DT-1', status: 'draft' as const },
    approved: { id: 90002, notation: 'TEST/DT-2', status: 'approved' as const },
  },
  handling: {
    active: { id: 9001, name: 'TEST: HSCV active', status: 1 as const },
    closed: { id: 9002, name: 'TEST: HSCV closed', status: 4 as const },
  },
  notices: [90001, 90002, 90003] as const,
} as const;

/**
 * Convenience: tổng số fixture docs (cho assertion smoke test "tab có data").
 */
export const TEST_DOCS_COUNTS = {
  incoming: 5,
  outgoing: 3,
  drafting: 2,
  handling: 2,
  notices: 3,
  total: 15, // 5+3+2+2+3 (kp incl users)
} as const;

/**
 * Backward-compat alias (plan 21-02 plan referenced INCOMING_DOCS, OUTGOING_DOCS).
 */
export const INCOMING_DOCS = TEST_DOCS.incoming;
export const OUTGOING_DOCS = TEST_DOCS.outgoing;
export const DRAFTING_DOCS = TEST_DOCS.drafting;
export const HANDLING_DOCS = TEST_DOCS.handling;
