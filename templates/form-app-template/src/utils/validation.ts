import { z } from 'zod';

// Base validation schema for contact form
export const contactFormSchema = z.object({
  name: z.string()
    .min(2, 'Namnet måste innehålla minst 2 tecken')
    .max(100, 'Namnet får inte vara längre än 100 tecken'),
  
  email: z.string()
    .email('Ogiltig e-postadress')
    .min(5, 'E-postadressen är för kort')
    .max(100, 'E-postadressen är för lång'),
  
  phone: z.string()
    .regex(/^(\+\d{1,3}\s?)?(\d{6,14})$/, 'Ogiltigt telefonnummer')
    .optional()
    .or(z.literal('')),
  
  message: z.string()
    .min(10, 'Meddelandet måste innehålla minst 10 tecken')
    .max(1000, 'Meddelandet får inte vara längre än 1000 tecken'),
  
  consent: z.boolean()
    .refine(val => val === true, {
      message: 'Du måste acceptera villkoren för att fortsätta',
      path: ['consent'],
    }),
});

// Type for form data based on the schema
export type ContactFormData = z.infer<typeof contactFormSchema>;

// Function to validate single field
export const validateField = (
  fieldName: keyof ContactFormData, 
  value: any
): string | null => {
  const validationResult = contactFormSchema.shape[fieldName].safeParse(value);
  
  if (!validationResult.success) {
    const error = validationResult.error.format();
    // @ts-ignore
    return error[fieldName]?._errors[0] || null;
  }
  
  return null;
};

// Extended schema with file validation
export const contactFormWithFileSchema = contactFormSchema.extend({
  file: z.instanceof(File)
    .refine(file => file.size <= 10 * 1024 * 1024, {
      message: 'Filen får inte vara större än 10MB',
    })
    .refine(
      file => 
        ['application/pdf', 'image/jpeg', 'image/png', 'image/jpg'].includes(
          file.type
        ),
      {
        message: 'Endast PDF, JPEG, eller PNG filer tillåts',
      }
    )
    .optional(),
});

export type ContactFormWithFileData = z.infer<typeof contactFormWithFileSchema>;
