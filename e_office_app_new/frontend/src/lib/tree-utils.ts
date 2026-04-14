import type { TreeNode } from '@/types/tree';

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
