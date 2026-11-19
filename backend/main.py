import re
from typing import List, Optional
from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import yt_dlp

app = FastAPI(title="Facebook Media Extractor API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

FB_REGEX = re.compile(
    r'^(https?:\/\/)?((www|m|web)\.)?(facebook\.com|fb\.watch)\/.*$',
    re.IGNORECASE
)

class ExtractRequest(BaseModel):
    url: str

class MediaFormat(BaseModel):
    format_id: str
    quality_label: str
    ext: str
    download_url: str
    filesize_approx: Optional[float] = None

class ExtractResponse(BaseModel):
    title: str
    thumbnail: Optional[str] = None
    duration: Optional[float] = None
    media_type: str
    formats: List[MediaFormat]

@app.post("/api/extract", response_model=ExtractResponse)
async def extract_facebook_media(payload: ExtractRequest):
    url = payload.url.strip()

    if not FB_REGEX.match(url):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="URL bukan merupakan tautan Facebook yang valid."
        )

    ydl_opts = {
        'quiet': True,
        'no_warnings': True,
        'format': 'best',
        'noplaylist': True,
        'extract_flat': False,
    }

    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=False)
            if not info:
                raise HTTPException(status_code=404, detail="Media tidak ditemukan atau bersifat privat.")

            title = info.get('title') or info.get('description') or "Facebook Media"
            thumbnail = info.get('thumbnail')
            duration = info.get('duration')
            media_type = "video"

            formats_list: List[MediaFormat] = []
            raw_formats = info.get('formats', [])

            if raw_formats:
                seen_labels = set()
                # Sort descending by resolution & bitrate
                sorted_formats = sorted(
                    [f for f in raw_formats if f.get('url')],
                    key=lambda x: (x.get('height') or 0, x.get('tbr') or 0),
                    reverse=True
                )

                for f in sorted_formats:
                    height = f.get('height')
                    ext = f.get('ext', 'mp4')
                    url_direct = f.get('url')
                    filesize = f.get('filesize') or f.get('filesize_approx')

                    if height and height >= 720:
                        label = f"HD ({height}p)"
                    elif height:
                        label = f"SD ({height}p)"
                    elif f.get('vcodec') == 'none' and f.get('acodec') != 'none':
                        label = "Audio Only (MP3)"
                        ext = "mp3"
                    else:
                        label = f"Standard ({ext.upper()})"

                    if label not in seen_labels and url_direct:
                        seen_labels.add(label)
                        formats_list.append(MediaFormat(
                            format_id=f.get('format_id', 'unknown'),
                            quality_label=label,
                            ext=ext,
                            download_url=url_direct,
                            filesize_approx=filesize
                        ))

            # Fallback jika tidak ada format list berjenjang
            if not formats_list and info.get('url'):
                formats_list.append(MediaFormat(
                    format_id="best",
                    quality_label="Kualitas Terbaik (Default)",
                    ext=info.get('ext', 'mp4'),
                    download_url=info['url'],
                    filesize_approx=info.get('filesize')
                ))

            return ExtractResponse(
                title=title[:120],
                thumbnail=thumbnail,
                duration=duration,
                media_type=media_type,
                formats=formats_list
            )

    except yt_dlp.utils.DownloadError:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Gagal mengekstrak konten. Pastikan postingan bersifat publik dan bukan grup privat."
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Terjadi kesalahan pada server: {str(e)}"
        )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
