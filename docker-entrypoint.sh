#!/bin/sh
set -e
if [ -n "$OCR_PROVIDER" ]; then ocr config set provider "$OCR_PROVIDER"; fi
if [ -n "$OCR_MODEL" ]; then ocr config set model "$OCR_MODEL"; fi
if [ -n "$OCR_CUSTOM_URL" ]; then
  ocr config set custom_providers."$OCR_PROVIDER".url "$OCR_CUSTOM_URL"
  ocr config set custom_providers."$OCR_PROVIDER".protocol "${OCR_CUSTOM_PROTOCOL:-openai}"
  if [ -n "$OCR_MODEL" ]; then ocr config set custom_providers."$OCR_PROVIDER".model "$OCR_MODEL"; fi
  if [ -n "$OCR_CUSTOM_API_KEY" ]; then ocr config set custom_providers."$OCR_PROVIDER".api_key "$OCR_CUSTOM_API_KEY"; fi
fi
exec ocr "$@"
