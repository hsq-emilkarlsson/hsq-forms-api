declare module '@hookform/resolvers/zod' {
  import { Resolver } from 'react-hook-form';
  import { ZodSchema } from 'zod';
  
  export function zodResolver<T = any>(schema: ZodSchema<T>): Resolver<T>;
}
