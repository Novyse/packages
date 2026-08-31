// OPAQUE password-authenticated key exchange protocol bindings.

use std::collections::HashMap;
use std::sync::{LazyLock, Mutex};
use std::sync::atomic::{AtomicI64, Ordering};

use opaque_ke::argon2::Argon2;
use opaque_ke::ciphersuite::CipherSuite;
use rand::rngs::OsRng;
use opaque_ke::{
    ClientLogin, ClientLoginFinishParameters, ClientRegistration,
    ClientRegistrationFinishParameters, CredentialFinalization, CredentialRequest,
    CredentialResponse, RegistrationRequest, RegistrationResponse, RegistrationUpload,
    ServerLogin, ServerLoginParameters, ServerRegistration, ServerSetup,
};

// ---------------------------------------------------------------------------
// Cipher Suite
// ---------------------------------------------------------------------------

struct DefaultCS;

impl CipherSuite for DefaultCS {
    type OprfCs = opaque_ke::Ristretto255;
    type KeyExchange = opaque_ke::TripleDh<opaque_ke::Ristretto255, sha2::Sha512>;
    type Ksf = Argon2<'static>;
}

// ---------------------------------------------------------------------------
// In-memory state registries
// ---------------------------------------------------------------------------

static CLIENT_REG_STORE: LazyLock<Mutex<HashMap<i64, ClientRegistration<DefaultCS>>>> =
    LazyLock::new(|| Mutex::new(HashMap::new()));

static CLIENT_LOG_STORE: LazyLock<Mutex<HashMap<i64, ClientLogin<DefaultCS>>>> =
    LazyLock::new(|| Mutex::new(HashMap::new()));

static SERVER_LOG_STORE: LazyLock<Mutex<HashMap<i64, ServerLogin<DefaultCS>>>> =
    LazyLock::new(|| Mutex::new(HashMap::new()));

static STATE_ID: AtomicI64 = AtomicI64::new(1);

fn next_id() -> i64 {
    STATE_ID.fetch_add(1, Ordering::SeqCst)
}

// ---------------------------------------------------------------------------
// DTOs
// ---------------------------------------------------------------------------

pub struct ClientRegistrationStartResult {
    pub state_id: i64,
    pub registration_request: Vec<u8>,
}

pub struct ClientRegistrationFinishResult {
    pub registration_upload: Vec<u8>,
    pub export_key: Vec<u8>,
}

pub struct ClientLoginStartResult {
    pub state_id: i64,
    pub credential_request: Vec<u8>,
}

pub struct ServerLoginStartResult {
    pub state_id: i64,
    pub credential_response: Vec<u8>,
}

pub struct ClientLoginFinishResult {
    pub credential_finalization: Vec<u8>,
    pub session_key: Vec<u8>,
    pub export_key: Vec<u8>,
}

// ---------------------------------------------------------------------------
// Server Setup
// ---------------------------------------------------------------------------

#[flutter_rust_bridge::frb(sync)]
pub fn server_setup_new() -> Result<Vec<u8>, String> {
    let mut rng = OsRng;
    let setup = ServerSetup::<DefaultCS>::new(&mut rng);
    Ok(setup.serialize().to_vec())
}

// ---------------------------------------------------------------------------
// Registration — client side
// ---------------------------------------------------------------------------

#[flutter_rust_bridge::frb(sync)]
pub fn client_registration_start(
    password: Vec<u8>,
) -> Result<ClientRegistrationStartResult, String> {
    let mut rng = OsRng;
    let result = ClientRegistration::<DefaultCS>::start(&mut rng, &password)
        .map_err(|e| e.to_string())?;
    let state_id = next_id();
    CLIENT_REG_STORE
        .lock()
        .map_err(|_| "state store unavailable".to_string())?
        .insert(state_id, result.state);
    Ok(ClientRegistrationStartResult {
        state_id,
        registration_request: result.message.serialize().to_vec(),
    })
}

#[flutter_rust_bridge::frb(sync)]
pub fn client_registration_finish(
    state_id: i64,
    password: Vec<u8>,
    registration_response: Vec<u8>,
) -> Result<ClientRegistrationFinishResult, String> {
    let state = CLIENT_REG_STORE
        .lock()
        .map_err(|_| "state store unavailable".to_string())?
        .remove(&state_id)
        .ok_or_else(|| format!("No client registration state for id={state_id}"))?;

    let response = RegistrationResponse::<DefaultCS>::deserialize(&registration_response)
        .map_err(|e| e.to_string())?;

    let mut rng = OsRng;
    let result = state
        .finish(
            &mut rng,
            &password,
            response,
            ClientRegistrationFinishParameters::default(),
        )
        .map_err(|e| e.to_string())?;

    Ok(ClientRegistrationFinishResult {
        registration_upload: result.message.serialize().to_vec(),
        export_key: result.export_key.to_vec(),
    })
}

// ---------------------------------------------------------------------------
// Registration — server side
// ---------------------------------------------------------------------------

#[flutter_rust_bridge::frb(sync)]
pub fn server_registration_start(
    server_setup: Vec<u8>,
    registration_request: Vec<u8>,
    credential_identifier: Vec<u8>,
) -> Result<Vec<u8>, String> {
    let setup = ServerSetup::<DefaultCS>::deserialize(&server_setup)
        .map_err(|e| e.to_string())?;
    let request = RegistrationRequest::<DefaultCS>::deserialize(&registration_request)
        .map_err(|e| e.to_string())?;
    let result = ServerRegistration::<DefaultCS>::start(&setup, request, &credential_identifier)
        .map_err(|e| e.to_string())?;
    Ok(result.message.serialize().to_vec())
}

#[flutter_rust_bridge::frb(sync)]
pub fn server_registration_finish(registration_upload: Vec<u8>) -> Result<Vec<u8>, String> {
    let upload = RegistrationUpload::<DefaultCS>::deserialize(&registration_upload)
        .map_err(|e| e.to_string())?;
    let password_file = ServerRegistration::finish(upload);
    Ok(password_file.serialize().to_vec())
}

// ---------------------------------------------------------------------------
// Login — client side
// ---------------------------------------------------------------------------

#[flutter_rust_bridge::frb(sync)]
pub fn client_login_start(password: Vec<u8>) -> Result<ClientLoginStartResult, String> {
    let mut rng = OsRng;
    let result = ClientLogin::<DefaultCS>::start(&mut rng, &password)
        .map_err(|e| e.to_string())?;
    let state_id = next_id();
    CLIENT_LOG_STORE
        .lock()
        .map_err(|_| "state store unavailable".to_string())?
        .insert(state_id, result.state);
    Ok(ClientLoginStartResult {
        state_id,
        credential_request: result.message.serialize().to_vec(),
    })
}

#[flutter_rust_bridge::frb(sync)]
pub fn client_login_finish(
    state_id: i64,
    password: Vec<u8>,
    credential_response: Vec<u8>,
) -> Result<ClientLoginFinishResult, String> {
    let state = CLIENT_LOG_STORE
        .lock()
        .map_err(|_| "state store unavailable".to_string())?
        .remove(&state_id)
        .ok_or_else(|| format!("No client login state for id={state_id}"))?;

    let response = CredentialResponse::<DefaultCS>::deserialize(&credential_response)
        .map_err(|e| e.to_string())?;

    let mut rng = OsRng;
    let result = state
        .finish(
            &mut rng,
            &password,
            response,
            ClientLoginFinishParameters::default(),
        )
        .map_err(|e| e.to_string())?;

    Ok(ClientLoginFinishResult {
        credential_finalization: result.message.serialize().to_vec(),
        session_key: result.session_key.to_vec(),
        export_key: result.export_key.to_vec(),
    })
}

// ---------------------------------------------------------------------------
// Login — server side
// ---------------------------------------------------------------------------

#[flutter_rust_bridge::frb(sync)]
pub fn server_login_start(
    server_setup: Vec<u8>,
    password_file: Vec<u8>,
    credential_request: Vec<u8>,
    credential_identifier: Vec<u8>,
) -> Result<ServerLoginStartResult, String> {
    let setup = ServerSetup::<DefaultCS>::deserialize(&server_setup)
        .map_err(|e| e.to_string())?;
    let file = ServerRegistration::<DefaultCS>::deserialize(&password_file)
        .map_err(|e| e.to_string())?;
    let request = CredentialRequest::<DefaultCS>::deserialize(&credential_request)
        .map_err(|e| e.to_string())?;

    let mut rng = OsRng;
    let result = ServerLogin::start(
        &mut rng,
        &setup,
        Some(file),
        request,
        &credential_identifier,
        ServerLoginParameters::default(),
    )
    .map_err(|e| e.to_string())?;

    let state_id = next_id();
    SERVER_LOG_STORE
        .lock()
        .map_err(|_| "state store unavailable".to_string())?
        .insert(state_id, result.state);

    Ok(ServerLoginStartResult {
        state_id,
        credential_response: result.message.serialize().to_vec(),
    })
}

#[flutter_rust_bridge::frb(sync)]
pub fn server_login_finish(
    state_id: i64,
    credential_finalization: Vec<u8>,
) -> Result<Vec<u8>, String> {
    let state = SERVER_LOG_STORE
        .lock()
        .map_err(|_| "state store unavailable".to_string())?
        .remove(&state_id)
        .ok_or_else(|| format!("No server login state for id={state_id}"))?;

    let finalization = CredentialFinalization::<DefaultCS>::deserialize(&credential_finalization)
        .map_err(|e| e.to_string())?;

    let result = state
        .finish(finalization, ServerLoginParameters::default())
        .map_err(|e| e.to_string())?;

    Ok(result.session_key.to_vec())
}
