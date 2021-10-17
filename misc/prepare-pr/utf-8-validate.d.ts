declare module "utf-8-validate" {
  export function isValidUTF8(buffer: Buffer): boolean;
  export default isValidUTF8;
}
