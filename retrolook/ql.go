package main

// #cgo darwin CFLAGS: -O3 -Wall -DNDEBUG -Winvalid-pch -m64 -msse4.2
// #cgo darwin LDFLAGS: -lobjc -framework Foundation -framework AppKit -framework QuickLook
// #include "ql.h"
import "C"
import (
	"bytes"
	"fmt"
	"image"
	_ "image/gif"
	_ "image/jpeg"
	"image/png"
	"io/ioutil"
	"log"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"unsafe"

	_ "github.com/samuel/go-macpaint/macpaint"
	_ "github.com/samuel/go-pcx/pcx"
	_ "github.com/samuel/go-psp/psp"
	_ "golang.org/x/image/bmp"
	_ "golang.org/x/image/webp"
)

type contentType int

const (
	contentTypePDF       contentType = C.CONTENT_TYPE_PDF
	contentTypeHTML      contentType = C.CONTENT_TYPE_HTML
	contentTypeXML       contentType = C.CONTENT_TYPE_XML
	contentTypePlainText contentType = C.CONTENT_TYPE_PLAIN_TEXT
	contentTypeRTF       contentType = C.CONTENT_TYPE_RTF
	contentTypeMovie     contentType = C.CONTENT_TYPE_MOVIE
	contentTypePNGImage  contentType = C.CONTENT_TYPE_PNG_IMAGE
	contentTypeAudio     contentType = C.CONTENT_TYPE_AUDIO
)

type preview struct {
	data        []byte
	contentType contentType
	properties  []property
}

type property interface {
	transform(*C.dict_pair)
}

type nameProperty string

func (p nameProperty) transform(d *C.dict_pair) {
	d.key = C.PREVIEW_PROPERTY_DISPLAY_NAME
	d.string_value = C.CString(string(p))
}

type widthProperty int

func (p widthProperty) transform(d *C.dict_pair) {
	d.key = C.PREVIEW_PROPERTY_WIDTH
	d.int64_value = C.int64_t(int64(p))
}

type heightProperty int

func (p heightProperty) transform(d *C.dict_pair) {
	d.key = C.PREVIEW_PROPERTY_HEIGHT
	d.int64_value = C.int64_t(int64(p))
}

type thumbnail struct {
	data []byte
}

//export generatePreviewForURL
func generatePreviewForURL(url *C.char, dataLen *C.ulong, contentType *C.int, properties **C.dict_pair, propertyCount *C.int) unsafe.Pointer {
	prev := genPreviewForURL(C.GoString(url))
	if prev != nil {
		*dataLen = C.ulong(len(prev.data))
		*contentType = C.int(prev.contentType)
		data := C.malloc(C.size_t(len(prev.data)))
		copy((*[1 << 30]byte)(data)[:len(prev.data)], prev.data)
		*properties = nil
		*propertyCount = C.int(len(prev.properties))
		if len(prev.properties) != 0 {
			*properties = (*C.dict_pair)(C.malloc(C.size_t(C.sizeof_dict_pair * len(prev.properties))))
			cProps := (*[1 << 10]C.dict_pair)(unsafe.Pointer(*properties))
			for i, p := range prev.properties {
				p.transform(&cProps[i])
			}
		}
		return data
	}
	return nil
}

//export generateThumbnailForURL
func generateThumbnailForURL(url *C.char, dataLen *C.ulong) unsafe.Pointer {
	thumb := genThumbnailForURL(C.GoString(url))
	if thumb != nil {
		*dataLen = C.ulong(len(thumb.data))
		data := C.malloc(C.size_t(len(thumb.data)))
		copy((*[1 << 30]byte)(data)[:len(thumb.data)], thumb.data)
		return data
	}
	return nil
}

func genPreviewForURL(earl string) *preview {
	log.SetFlags(log.Ldate | log.Ltime | log.Lmicroseconds | log.Lshortfile)
	ur, err := url.Parse(earl)
	if err != nil {
		log.Printf("Failed to parse URL %q: %s", earl, err)
		return nil
	}
	if ur.Scheme != "file" {
		return nil
	}
	switch strings.ToLower(filepath.Ext(ur.Path)) {
	case ".z80", ".asm":
		b, err := ioutil.ReadFile(ur.Path)
		if err != nil {
			log.Printf("Failed to read path %q: %s", ur.Path, err)
			return nil
		}
		return &preview{
			data:        b,
			contentType: contentTypePlainText,
			properties: []property{
				nameProperty("Z80 Assembly"),
			},
		}
	case ".pcx", ".psp", ".pspimage", ".mac":
		f, err := os.Open(ur.Path)
		if err != nil {
			log.Printf("Failed to open path %q: %s", ur.Path, err)
			return nil
		}
		defer f.Close()
		m, _, err := image.Decode(f)
		if err != nil {
			log.Printf("Failed to decode %q: %s", ur.Path, err)
			return nil
		}
		// TODO: use format to choose beween png and jpeg
		buf := &bytes.Buffer{}
		if err := png.Encode(buf, m); err != nil {
			log.Printf("Failed to encode %q: %s", ur.Path, err)
			return nil
		}
		imageType := "Other"
		switch im := m.(type) {
		case *image.NRGBA, *image.RGBA:
			imageType = "RGB"
		case *image.Paletted:
			imageType = fmt.Sprintf("%d Color", len(im.Palette))
		case *image.Gray:
			imageType = "Gray"
		case *image.YCbCr:
			imageType = "YCbCr"
		}
		return &preview{
			data:        buf.Bytes(),
			contentType: contentTypePNGImage,
			properties: []property{
				nameProperty(fmt.Sprintf("%dx%d • %s • %s", m.Bounds().Dx(), m.Bounds().Dy(), imageType, filepath.Base(ur.Path))),
				widthProperty(m.Bounds().Dx()),
				heightProperty(m.Bounds().Dy()),
			},
		}
	}
	return nil
}

func genThumbnailForURL(earl string) *thumbnail {
	log.SetFlags(log.Ldate | log.Ltime | log.Lmicroseconds | log.Lshortfile)
	ur, err := url.Parse(earl)
	if err != nil {
		log.Printf("Failed to parse URL %q: %s", earl, err)
		return nil
	}
	if ur.Scheme != "file" {
		return nil
	}
	switch strings.ToLower(filepath.Ext(ur.Path)) {
	case ".pcx", ".psp", ".pspimage", ".mac":
		f, err := os.Open(ur.Path)
		if err != nil {
			log.Printf("Failed to open path %q: %s", ur.Path, err)
			return nil
		}
		defer f.Close()
		m, _, err := image.Decode(f)
		if err != nil {
			log.Printf("Failed to decode %q: %s", ur.Path, err)
			return nil
		}
		// TODO: use format to choose beween png and jpeg
		buf := &bytes.Buffer{}
		if err := png.Encode(buf, m); err != nil {
			log.Printf("Failed to encode %q: %s", ur.Path, err)
			return nil
		}
		return &thumbnail{
			data: buf.Bytes(),
		}
	}
	return nil
}

func main() {}
