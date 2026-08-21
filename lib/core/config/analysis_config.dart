/// Base URL of the hosted analysis service (see /analysis_service — a
/// small FastAPI app running Spotify's Basic Pitch model). Update this
/// once the service is deployed.
const analysisServiceBaseUrl = 'https://musiclab-geb6.onrender.com';

/// Base URL of the hosted OMR service (see /omr_service — a small FastAPI
/// app running the open-source oemer model to read a time signature off
/// sheet music). Update this once the service is deployed.
const omrServiceBaseUrl = 'https://musiclab-1-lb5k.onrender.com';
