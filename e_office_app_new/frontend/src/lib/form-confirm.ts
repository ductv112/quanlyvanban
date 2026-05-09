/**
 * Helper hiển thị dialog xác nhận khi người dùng click Hủy nhưng form đã thay đổi dữ liệu.
 *
 * Bug được fix: #8, #11, #24, #34, #55, #60, #62 (tester báo: click Hủy không có dialog xác nhận).
 *
 * Sử dụng:
 *   const { modal } = App.useApp();
 *   const onCancel = () => confirmCloseIfDirty(form, modal, doClose);
 */
import type { FormInstance } from 'antd';
import type { HookAPI as ModalHookAPI } from 'antd/es/modal/useModal';

/**
 * Kiểm tra form có dirty (đã thay đổi so với initial values) hay không.
 * Đối chiếu với baseline đã set bằng form.setFieldsValue / initialValues.
 */
export function isFormDirty(form: FormInstance): boolean {
  // AntD lưu list field đã touch — coi như dirty nếu user đã chạm vào ít nhất 1 field
  if (typeof form.isFieldsTouched === 'function' && form.isFieldsTouched()) return true;
  return false;
}

/**
 * Hiển thị dialog xác nhận hủy nếu form dirty. Nếu form chưa dirty → đóng luôn (không hỏi).
 *
 * @param form           - AntD Form instance
 * @param modal          - hook từ App.useApp() (.modal)
 * @param onConfirmClose - callback chạy khi user xác nhận hủy (đóng drawer + reset state)
 * @param opts.title     - tiêu đề dialog (mặc định: "Xác nhận hủy")
 * @param opts.content   - nội dung dialog (mặc định: "Dữ liệu đã thay đổi sẽ không được lưu...")
 */
export function confirmCloseIfDirty(
  form: FormInstance,
  modal: ModalHookAPI,
  onConfirmClose: () => void,
  opts?: { title?: string; content?: string },
): void {
  if (!isFormDirty(form)) {
    onConfirmClose();
    return;
  }
  modal.confirm({
    title: opts?.title || 'Xác nhận hủy',
    content: opts?.content || 'Dữ liệu đã nhập sẽ không được lưu. Bạn có chắc chắn muốn hủy?',
    okText: 'Hủy nhập',
    okButtonProps: { danger: true },
    cancelText: 'Tiếp tục nhập',
    onOk: () => onConfirmClose(),
  });
}
