import React, { useState, useCallback } from 'react';
import './FileUpload.css';

export interface FileUploadProps {
  submissionId?: string;
  onFilesUploaded?: (files: FileUploadResult[]) => void;
  maxFiles?: number;
  maxSizePerFile?: number; // in bytes
  acceptedTypes?: string[];
  disabled?: boolean;
}

export interface FileUploadResult {
  success: boolean;
  message: string;
  file_id?: string;
  original_filename?: string;
  file_size?: number;
}

const FileUpload: React.FC<FileUploadProps> = ({
  submissionId,
  onFilesUploaded,
  maxFiles = 5,
  maxSizePerFile = 10 * 1024 * 1024, // 10MB
  acceptedTypes = [
    'image/jpeg', 'image/png', 'image/gif', 'image/webp',
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'text/plain', 'text/csv'
  ],
  disabled = false
}) => {
  const [selectedFiles, setSelectedFiles] = useState<File[]>([]);
  const [uploading, setUploading] = useState(false);
  const [uploadResults, setUploadResults] = useState<FileUploadResult[]>([]);
  const [dragOver, setDragOver] = useState(false);

  const validateFile = useCallback((file: File): string | null => {
    if (file.size > maxSizePerFile) {
      return `Filen "${file.name}" är för stor. Max storlek är ${(maxSizePerFile / (1024 * 1024)).toFixed(1)}MB`;
    }

    if (!acceptedTypes.includes(file.type)) {
      return `Filtypen "${file.type}" är inte tillåten för "${file.name}"`;
    }

    return null;
  }, [maxSizePerFile, acceptedTypes]);

  const handleFileSelect = useCallback((files: FileList | File[]) => {
    const fileArray = Array.from(files);
    const errors: string[] = [];
    const validFiles: File[] = [];

    // Kontrollera antal filer
    if (selectedFiles.length + fileArray.length > maxFiles) {
      errors.push(`Maximalt ${maxFiles} filer tillåtna`);
      return;
    }

    // Validera varje fil
    fileArray.forEach(file => {
      const error = validateFile(file);
      if (error) {
        errors.push(error);
      } else {
        validFiles.push(file);
      }
    });

    if (errors.length > 0) {
      alert('Filfel:\\n' + errors.join('\\n'));
      return;
    }

    setSelectedFiles(prev => [...prev, ...validFiles]);
  }, [selectedFiles.length, maxFiles, validateFile]);

  const handleDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setDragOver(false);
    
    if (disabled) return;
    
    const files = e.dataTransfer.files;
    handleFileSelect(files);
  }, [disabled, handleFileSelect]);

  const handleDragOver = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    if (!disabled) {
      setDragOver(true);
    }
  }, [disabled]);

  const handleDragLeave = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setDragOver(false);
  }, []);

  const removeFile = useCallback((index: number) => {
    setSelectedFiles(prev => prev.filter((_, i) => i !== index));
  }, []);

  const uploadFiles = async () => {
    if (!submissionId || selectedFiles.length === 0) {
      alert('Inga filer valda eller submission ID saknas');
      return;
    }

    setUploading(true);
    setUploadResults([]);

    try {
      const formData = new FormData();
      selectedFiles.forEach(file => {
        formData.append('files', file);
      });

      const isProd = import.meta.env.PROD;
      const apiUrl = isProd 
        ? 'https://hsq-forms-api.agreeableglacier-1e56cfbb.westeurope.azurecontainerapps.io'
        : 'http://localhost:8000';
      const response = await fetch(`${apiUrl}/files/upload/${submissionId}`, {
        method: 'POST',
        body: formData,
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const results: FileUploadResult[] = await response.json();
      setUploadResults(results);
      
      // Rensa framgångsrikt uppladdade filer
      const successfulFiles = results.filter(r => r.success);
      if (successfulFiles.length > 0) {
        setSelectedFiles([]);
      }

      onFilesUploaded?.(results);

    } catch (error) {
      console.error('Upload error:', error);
      const errorResults: FileUploadResult[] = selectedFiles.map(file => ({
        success: false,
        message: `Fel vid uppladdning av ${file.name}: ${error instanceof Error ? error.message : 'Okänt fel'}`,
        original_filename: file.name
      }));
      setUploadResults(errorResults);
    } finally {
      setUploading(false);
    }
  };

  const formatFileSize = (bytes: number): string => {
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  };

  const getAcceptedExtensions = (): string => {
    const extensionMap: Record<string, string[]> = {
      'image/jpeg': ['.jpg', '.jpeg'],
      'image/png': ['.png'],
      'image/gif': ['.gif'],
      'image/webp': ['.webp'],
      'application/pdf': ['.pdf'],
      'application/msword': ['.doc'],
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document': ['.docx'],
      'application/vnd.ms-excel': ['.xls'],
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': ['.xlsx'],
      'text/plain': ['.txt'],
      'text/csv': ['.csv']
    };

    const extensions = acceptedTypes.flatMap(type => extensionMap[type] || []);
    return extensions.join(', ');
  };

  return (
    <div className="file-upload">
      <div 
        className={`file-drop-zone ${dragOver ? 'drag-over' : ''} ${disabled ? 'disabled' : ''}`}
        onDrop={handleDrop}
        onDragOver={handleDragOver}
        onDragLeave={handleDragLeave}
      >
        <div className="drop-zone-content">
          <svg className="upload-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor">
            <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
            <polyline points="7,10 12,15 17,10" />
            <line x1="12" y1="15" x2="12" y2="3" />
          </svg>
          <p className="drop-text">
            Dra och släpp filer här eller{' '}
            <label className="file-select-label">
              <input
                type="file"
                multiple
                accept={acceptedTypes.join(',')}
                onChange={(e) => e.target.files && handleFileSelect(e.target.files)}
                disabled={disabled}
                style={{ display: 'none' }}
              />
              <span className="file-select-button">välj filer</span>
            </label>
          </p>
          <p className="file-info">
            Max {maxFiles} filer, {(maxSizePerFile / (1024 * 1024)).toFixed(1)}MB per fil
          </p>
          <p className="accepted-types">
            Accepterade filtyper: {getAcceptedExtensions()}
          </p>
        </div>
      </div>

      {selectedFiles.length > 0 && (
        <div className="selected-files">
          <h4>Valda filer ({selectedFiles.length}/{maxFiles})</h4>
          <ul className="file-list">
            {selectedFiles.map((file, index) => (
              <li key={index} className="file-item">
                <div className="file-info">
                  <span className="file-name">{file.name}</span>
                  <span className="file-size">{formatFileSize(file.size)}</span>
                </div>
                <button
                  type="button"
                  className="remove-file-btn"
                  onClick={() => removeFile(index)}
                  disabled={uploading}
                >
                  ✕
                </button>
              </li>
            ))}
          </ul>
          
          <button
            type="button"
            className="upload-btn"
            onClick={uploadFiles}
            disabled={uploading || !submissionId || selectedFiles.length === 0}
          >
            {uploading ? 'Laddar upp...' : `Ladda upp ${selectedFiles.length} fil${selectedFiles.length !== 1 ? 'er' : ''}`}
          </button>
        </div>
      )}

      {uploadResults.length > 0 && (
        <div className="upload-results">
          <h4>Uppladdningsresultat</h4>
          <ul className="result-list">
            {uploadResults.map((result, index) => (
              <li key={index} className={`result-item ${result.success ? 'success' : 'error'}`}>
                <div className="result-icon">
                  {result.success ? '✓' : '✗'}
                </div>
                <div className="result-message">
                  {result.message}
                  {result.file_size && (
                    <span className="result-size"> ({formatFileSize(result.file_size)})</span>
                  )}
                </div>
              </li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
};

export default FileUpload;
