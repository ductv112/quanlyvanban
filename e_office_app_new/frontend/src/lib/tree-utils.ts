import type { TreeNode } from '@/types/tree';

/**
 * Xây cây từ mảng phẳng {id, name, parent_id}.
 * Trả về mảng các node gốc với children đã được gắn vào.
 */
export function buildTree<T extends { id: number; parent_id: number | null; children?: T[] }>(
  items: T[]
): T[] {
  const map = new Map<number, T & { children: T[] }>();
  items.forEach((item) => map.set(item.id, { ...item, children: [] }));
  const roots: (T & { children: T[] })[] = [];
  map.forEach((node) => {
    if (node.parent_id !== null && node.parent_id !== undefined && map.has(node.parent_id)) {
      map.get(node.parent_id)!.children.push(node);
    } else {
      roots.push(node);
    }
  });
  return roots as T[];
}

/**
 * Đệ quy lọc cây theo từ khóa (so khớp title không phân biệt hoa thường).
 * Giữ lại node cha nếu bất kỳ node con nào khớp.
 */
export function filterTree(nodes: TreeNode[], keyword: string): TreeNode[] {
  if (!keyword.trim()) return nodes;
  return nodes
    .map((node) => {
      const children = node.children ? filterTree(node.children, keyword) : [];
      if (
        (node.title as string).toLowerCase().includes(keyword.toLowerCase()) ||
        children.length > 0
      ) {
        return { ...node, children };
      }
      return null;
    })
    .filter(Boolean) as TreeNode[];
}

/**
 * Chuyển đổi TreeNode[] thành định dạng treeData cho Ant Design TreeSelect.
 * Mỗi node: { value: key, title, children }
 */
export function flattenTreeForSelect(
  nodes: TreeNode[]
): { value: number; title: string; children?: any[] }[] {
  return nodes.map((n) => ({
    value: n.key,
    title: n.title,
    children: n.children ? flattenTreeForSelect(n.children) : undefined,
  }));
}
