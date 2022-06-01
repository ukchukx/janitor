const makeRequest = (url, method = 'get', body = null) => {
  if (body) body = JSON.stringify(body);

  const headerObject = { 'Content-Type': 'application/json' };

  const token = document.head.querySelector('meta[name="csrf-token"]');
  if (token) headerObject['X-CSRF-TOKEN'] = token.content;

  return fetch(url, { 
    method, 
    body,
    credentials: 'include',
    headers: new Headers(headerObject) 
  });
};

const downloadBlob = (blob, filename = 'download.sql') => {
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  
  // Click handler that releases the object URL after the element has been clicked
  // This is required for one-off downloads of the blob content
  const clickHandler = () => {
    setTimeout(() => {
      URL.revokeObjectURL(url);
      a.removeEventListener('click', clickHandler);
    }, 150);
  };
  
  a.addEventListener('click', clickHandler, false);
  a.click();
};

const downloadBackupFile = (url, fileName) => {
  return fetch(url)
    .then(response => response.blob())
    .then((blob) => {
      downloadBlob(blob, fileName);
    });
}

export { makeRequest, downloadBackupFile };
