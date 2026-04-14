export interface TreeNode {
  key: number;
  title: string;
  children?: TreeNode[];
  [key: string]: any;
}
