export default class CirrusService {
  /**
   * Delete a file in Cirrus
   */
  static async deleteFile(
    rootDir: string,
    fileName: string,
    deviceSerial?: string,
  ): Promise<void> {
    const params = new URLSearchParams();
    params.append('rootDir', rootDir);
    params.append('filePaths', fileName);
    if (deviceSerial) {
      params.append('serial', deviceSerial);
    }
    const url = `/api/v1/cirrus?${params}`;
    const response = await HttpService.delete(url);
    if (!response.ok) throw new Error('Failed to delete file');
  }

  /**
   * Construct a download URL for a Cirrus file. Clients may use this
   * directly as an `src` for iframes or anchors.
   */
  static getDownloadUrl(filePath: string, serial?: string): string {
    const params = new URLSearchParams({ filePath });
    if (serial) {
      params.append('serial', serial);
    }
    return `/api/v1/cirrus/download?${params}`;
  }

  /**
   * Move or rename a file or directory in Cirrus
   */
  static async moveFile(
    oldPath: string,
    newPath: string,
    oldDeviceSerial?: string,
    newDeviceSerial?: string,
  ): Promise<void> {
    await HttpService.put('/api/v1/cirrus', {
      oldFilePath: oldPath,
      newFilePath: newPath,
      oldDeviceSerial: oldDeviceSerial,
      newDeviceSerial: newDeviceSerial,
    });
  }

  /**
   * Upload files to Cirrus
   */
  static async uploadFiles(
    uploadPath: string,
    files: FileList | File[],
    serial?: string,
  ): Promise<Response> {
    const formData = new FormData();
    for (const file of Array.from(files)) {
      formData.append('files', file);
    }
    return CirrusService.uploadFilesFromFormData(uploadPath, formData, serial);
  }

  static async uploadFilesFromFormData(
    uploadPath: string,
    formData: FormData,
    serial?: string,
  ): Promise<Response> {
    const url = `${joinPaths('/api/v1/cirrus/upload', uploadPath)}${serial ? `?${new URLSearchParams({ serial })}` : ''}`;
    const response = await HttpService.postForm(url, formData);
    if (!response.ok) throw new Error('Upload failed');
    return response;
}
