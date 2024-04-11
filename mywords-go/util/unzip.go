package util

import (
	"archive/zip"
	"compress/gzip"
	"fmt"
	"io"
	"os"
	"path/filepath"
)

func Unzip(zipFilePath string, destPath string) error {
	return unzip(zipFilePath, destPath)
}

func unzip(zipFilePath string, destPath string) error {
	r, err := zip.OpenReader(zipFilePath)
	if err != nil {
		return err
	}
	defer r.Close()
	err = os.MkdirAll(destPath, 0755)
	if err != nil {
		return err
	}
	for _, file := range r.File {
		if file.FileInfo().IsDir() {
			fmt.Printf("Skipping directory: %s\n", file.Name)
			err = os.MkdirAll(filepath.Join(destPath, file.Name), file.Mode())
			if err != nil {
				return err
			}
			continue
		}
		path := filepath.Join(destPath, file.Name)
		err = unzipZFile(file, path)
		if err != nil {
			return err
		}
	}
	return nil
}

func unzipZFileWithGZip(file *zip.File, destPath string) error {
	fr, err := file.Open()
	if err != nil {
		return err
	}
	defer fr.Close()
	err = os.MkdirAll(filepath.Dir(destPath), 0755)
	if err != nil {
		return err
	}
	fw, err := os.Create(destPath)
	if err != nil {
		return err
	}
	defer fw.Close()
	gw, _ := gzip.NewWriterLevel(fw, gzip.BestCompression)
	defer gw.Close()
	_, err = io.Copy(gw, fr)
	if err != nil {
		return err
	}
	return nil
}
func unzipZFile(file *zip.File, destPath string) error {
	fr, err := file.Open()
	if err != nil {
		return err
	}
	defer fr.Close()
	err = os.MkdirAll(filepath.Dir(destPath), 0755)
	if err != nil {
		return err
	}
	fw, err := os.Create(destPath)
	if err != nil {
		return err
	}
	defer fw.Close()
	_, err = io.Copy(fw, fr)
	if err != nil {
		return err
	}
	return nil
}
