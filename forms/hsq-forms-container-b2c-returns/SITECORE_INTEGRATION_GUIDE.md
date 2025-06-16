# HSQ B2C Returns Form - Sitecore Integration Guide

## Overview
The HSQ B2C Returns Form has been enhanced to support iframe embedding in Sitecore CMS using the Embeddable Forms Framework (EFF). This form is optimized for consumer customers with personal information fields instead of company details.

## Key Features for Sitecore Integration

### 1. Iframe Detection & Optimization
- Automatically detects when running in iframe context
- Removes header/footer when embedded
- Applies iframe-specific styling
- Supports responsive design within containers

### 2. Accessibility Compliance
- Full ARIA attribute support (`aria-live`, `aria-relevant`, `aria-labelledby`)
- Screen reader compatibility
- Proper form field relationships
- Real-time validation announcements

### 3. Multi-language Support
- Swedish (`/sv`), English (`/en`), German (`/de`)
- Dynamic language switching
- Localized validation messages
- RTL language ready structure

### 4. Responsive Design
- Mobile-first approach
- Flexible grid layouts
- Compact mode for tight spaces
- Automatic field size adjustments

## Integration Options

### Option 1: Standard Iframe Embedding
```html
<iframe 
    src="http://localhost:3006/sv" 
    width="100%" 
    height="800"
    title="B2C Returns Form"
    style="border: none; border-radius: 8px;">
</iframe>
```

### Option 2: Embedded Mode (Recommended for Sitecore)
```html
<iframe 
    src="http://localhost:3006/sv?embed=true" 
    width="100%" 
    height="700"
    title="B2C Returns Form - Embedded"
    style="border: none;">
</iframe>
```

### Option 3: Compact Mode
```html
<iframe 
    src="http://localhost:3006/sv?embed=true&compact=true" 
    width="100%" 
    height="600"
    title="B2C Returns Form - Compact"
    style="border: none;">
</iframe>
```

## URL Parameters

| Parameter | Values | Description |
|-----------|--------|-------------|
| `embed` | `true`, `1` | Removes header/footer, optimizes for iframe |
| `compact` | `true`, `1` | Reduces spacing, smaller form elements |
| Language | `sv`, `en`, `de` | Sets form language |

## CSS Classes for Styling

### Container Classes
- `.iframe-embedded` - Applied to body when in iframe mode
- `.iframe-form-container` - Main form container in iframe mode
- `.form-loading` - Applied during form submission

### Accessibility Classes
- `.sr-only` - Screen reader only content
- `.error-message` - Error message styling
- `.success-message` - Success notification styling

## Sitecore Implementation Steps

### 1. Add Reference to EFF Script
```html
<script 
    type="text/javascript" 
    src="https://your-site.com/sitecore-embeddableforms.umd.js?sc_apikey=YOUR-API-KEY">
</script>
```

### 2. Add Form Component
```html
<scef-form formId="{YOUR-FORM-ID}">
    <iframe 
        src="http://your-domain.com/hsq-b2c-returns/sv?embed=true"
        width="100%"
        height="700"
        title="B2C Returns Form"
        style="border: none;">
    </iframe>
</scef-form>
```

### 3. Custom CSS for Sitecore Integration
```css
/* Sitecore-specific iframe styling */
.sitecore-form-container iframe {
    width: 100%;
    min-height: 600px;
    border: none;
    border-radius: 8px;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

/* Responsive adjustments */
@media (max-width: 768px) {
    .sitecore-form-container iframe {
        min-height: 550px;
    }
}
```

## Form Schema (B2C-specific)

### Personal Information
- First Name (required)
- Last Name (required)
- Email Address (required)
- Phone Number (optional)
- Address (required)
- Postal Code (required)
- City (required)

### Product Information
- Order Number (optional - B2C customers may not have this)
- Product Model (required)
- Serial Number (optional)
- Purchase Date (required)

### Return Details
- Return Reason (required): defective, not_as_described, damaged, wrong_item, other
- Product Condition (required): new, used, damaged
- Detailed Description (required, min 10 characters)

### Return Preferences
- Preferred Resolution (required): original_payment, store_credit, replacement

## API Integration

The form submits to:
```
POST /api/forms/submit
Content-Type: application/json

{
  "form_type": "b2c-returns",
  "data": { ... form data ... }
}
```

## Testing

Use the included `iframe-test.html` file to test different embedding scenarios:

1. **Standard Embedding**: Full layout with header
2. **Embedded Mode**: Clean layout without header/footer
3. **Compact Mode**: Space-efficient for narrow containers
4. **Multi-language**: Test all language versions

## Browser Compatibility

- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+
- Mobile browsers (iOS Safari, Chrome Mobile)

## Security Considerations

1. **CORS Configuration**: Ensure proper CORS headers for iframe embedding
2. **CSP Policies**: Update Content Security Policy to allow iframe sources
3. **HTTPS**: Use HTTPS in production for secure form submission
4. **API Authentication**: Implement proper API key validation

## Performance Optimization

1. **Lazy Loading**: Consider lazy loading iframes for better page performance
2. **Preloading**: Preload critical form resources
3. **Caching**: Implement appropriate caching headers
4. **Compression**: Enable gzip compression for assets

## Troubleshooting

### Common Issues

1. **Iframe Not Loading**
   - Check CORS headers
   - Verify URL accessibility
   - Check browser console for errors

2. **Form Not Responsive**
   - Ensure container has proper CSS
   - Check viewport meta tag
   - Verify responsive CSS classes

3. **Language Not Changing**
   - Check URL parameters
   - Verify language codes (sv, en, de)
   - Clear browser cache

4. **Accessibility Issues**
   - Test with screen readers
   - Verify ARIA attributes
   - Check keyboard navigation

## Deployment Checklist

- [ ] Form builds successfully (`npm run build`)
- [ ] Docker container created and tested
- [ ] All language versions working
- [ ] Iframe embedding tested in multiple scenarios
- [ ] Accessibility validated with screen readers
- [ ] API integration tested
- [ ] Error handling verified
- [ ] Mobile responsiveness confirmed
- [ ] Cross-browser compatibility checked

## Support

For technical support or questions about the B2C Returns Form:
1. Check the iframe-test.html for examples
2. Review browser console for error messages
3. Verify API endpoints are accessible
4. Test form functionality outside of iframe first
