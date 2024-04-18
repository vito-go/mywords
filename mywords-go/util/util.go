package util

import (
	"archive/zip"
	"io"
	"io/fs"
	"os"
	"path/filepath"
)

// Zip zip file or directory.
func Zip(targetZipPath, srcPath string) error {
	fInfo, err := os.Stat(srcPath)
	if err != nil {
		return err
	}
	if fInfo.IsDir() {
		return zipDir(targetZipPath, srcPath)
	}
	return zipFile(targetZipPath, srcPath)
}
func zipFile(zipFilePath string, filePath string) error {
	f, err := os.Create(zipFilePath)
	if err != nil {
		return err
	}
	defer func() {
		err = f.Close()
	}()
	zw := zip.NewWriter(f)
	defer func() {
		err = zw.Close()
	}()
	w, err := zw.Create(filepath.Base(filePath))
	if err != nil {
		return err
	}
	pathF, err := os.Open(filePath)
	if err != nil {
		return err
	}
	defer pathF.Close()
	_, err = io.Copy(w, pathF)
	if err != nil {
		return err
	}
	return nil
}

func zipDir(zipFilePath string, zipDir string) error {
	f, err := os.Create(zipFilePath)
	if err != nil {
		return err
	}
	defer func() {
		err = f.Close()
	}()
	return zipToWriter(f, zipDir)
}

func ZipToWriter(writer io.Writer, zipDir string) (err error) {
	return zipToWriter(writer, zipDir)
}
func zipToWriter(writer io.Writer, zipDir string) (err error) {
	zw := zip.NewWriter(writer)
	defer func() {
		if err = zw.Close(); err != nil {
			return
		}
	}()
	zipDir = filepath.ToSlash(zipDir)
	baseDir := filepath.ToSlash(filepath.Base(zipDir))
	err = filepath.WalkDir(zipDir, func(path string, d fs.DirEntry, err error) error {
		if d.IsDir() {
			return nil
		}
		path = filepath.ToSlash(path)
		relPath, err := filepath.Rel(zipDir, path)
		if err != nil {
			return err
		}
		zipPath := filepath.ToSlash(filepath.Join(baseDir, relPath))
		w, err := zw.Create(zipPath)
		if err != nil {
			return err
		}
		pathF, err := os.Open(path)
		if err != nil {
			return err
		}
		defer pathF.Close()
		_, err = io.Copy(w, pathF)
		if err != nil {
			return err
		}
		return nil
	})
	if err != nil {
		return err
	}
	return nil
}
