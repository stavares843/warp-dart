import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:warp_dart/warp.dart';
import 'package:warp_dart/warp_dart_bindings_generated.dart';

class Role {
  late String name;
  late int level;
  Role(Pointer<G_Role> pointer) {
    name = bindings.multipass_role_name(pointer).cast<Utf8>().toDartString();
    level = bindings.multipass_role_level(pointer);
    bindings.role_free(pointer);
  }
}

class Badge {
  late String name;
  late String icon;
  Badge(Pointer<G_Badge> pointer) {
    name = bindings.multipass_badge_name(pointer).cast<Utf8>().toDartString();
    icon = bindings.multipass_badge_icon(pointer).cast<Utf8>().toDartString();
    bindings.badge_free(pointer);
  }
}

class Identifier {
  late Pointer<G_Identifier> _pointer;
  Identifier(this._pointer);

  Identifier.fromUserName(String username) {
    _pointer = bindings
        .multipass_identifier_user_name(username.toNativeUtf8().cast<Char>());
  }

  Identifier.fromDID(String did_key) {
    DID did;
    try {
      did = DID.fromString(did_key);
    } on WarpException {
      rethrow;
    }
    Pointer<G_Identifier> ptr =
        bindings.multipass_identifier_did_key(did.pointer);
    did.drop();
    _pointer = ptr;
  }

  Identifier.own() {
    _pointer = bindings.multipass_identifier_own();
  }

  Pointer<G_Identifier> pointer() {
    return _pointer;
  }

  void drop() {
    bindings.identifier_free(_pointer);
  }
}

class IdentityUpdate {
  late Pointer<G_IdentityUpdate> pointer;
  IdentityUpdate(this.pointer);

  IdentityUpdate.setUsername(String username) {
    pointer = bindings.multipass_identity_update_set_username(
        username.toNativeUtf8().cast<Char>());
  }
  IdentityUpdate.setStatusMessage(String status) {
    pointer = bindings.multipass_identity_update_set_status_message(
        status.toNativeUtf8().cast<Char>());
  }
  IdentityUpdate.setPicture(String picture) {
    pointer = bindings.multipass_identity_update_set_graphics_picture(
        picture.toNativeUtf8().cast<Char>());
  }
  IdentityUpdate.setBanner(String banner) {
    pointer = bindings.multipass_identity_update_set_graphics_banner(
        banner.toNativeUtf8().cast<Char>());
  }
  void drop() {
    bindings.identityupdate_free(pointer);
  }
}

class Graphics {
  late String profile_picture;
  late String profile_banner;
  Graphics(Pointer<G_Graphics> pointer) {
    profile_picture = bindings
        .multipass_graphics_profile_picture(pointer)
        .cast<Utf8>()
        .toDartString();
    profile_banner = bindings
        .multipass_graphics_profile_banner(pointer)
        .cast<Utf8>()
        .toDartString();
    bindings.graphics_free(pointer);
  }
}

class Identity {
  late String username;
  late String short_id;
  late String did_key;
  late Graphics graphics;
  late String? status_message;
  //late List<Role> roles;
  //late List<Badge> available_badges;
  //late Badge active_badge;
  //late Map<String, String> linked_accounts;
  Identity(Pointer<G_Identity> pointer) {
    Pointer<Char> pUsername = bindings.multipass_identity_username(pointer);
    username = pUsername.cast<Utf8>().toDartString();
    Pointer<Char> pShortId = bindings.multipass_identity_short_id(pointer);
    short_id = pShortId.cast<Utf8>().toDartString();
    DID did = DID(bindings.multipass_identity_did_key(pointer));
    did_key = did.toString();
    graphics = Graphics(bindings.multipass_identity_graphics(pointer));
    Pointer<Char> ptr = bindings.multipass_identity_status_message(pointer);
    status_message = ptr != nullptr ? ptr.cast<Utf8>().toDartString() : null;

    //TODO: Complete
    calloc.free(pShortId);
    calloc.free(ptr);
    calloc.free(pUsername);
    did.drop();
    bindings.identity_free(pointer);
  }
}

enum FriendRequestStatusEnum {
  uninitialized,
  pending,
  accepted,
  denied,
  friendRemoved,
  requestRemoved
}

enum IdentityStatus { online, offline }

class Relationship {
  bool friends = false;
  bool receivedFriendRequest = false;
  bool sentFriendRequest = false;
  bool blocked = false;
  Relationship(Pointer<G_Relationship> pointer) {
    friends = bindings.multipass_identity_relationship_friends(pointer) != 0;
    receivedFriendRequest = bindings
            .multipass_identity_relationship_received_friend_request(pointer) !=
        0;
    sentFriendRequest =
        bindings.multipass_identity_relationship_sent_friend_request(pointer) !=
            0;
    blocked = bindings.multipass_identity_relationship_blocked(pointer) != 0;

    bindings.relationship_free(pointer);
  }
}

class FriendRequest {
  late String from;
  late String to;
  late FriendRequestStatusEnum status;
  // late int date;

  FriendRequest(Pointer<G_FriendRequest> pointer) {
    DID did_from;
    DID did_to;

    try {
      did_from = DID(bindings.multipass_friend_request_from(pointer));
      did_to = DID(bindings.multipass_friend_request_to(pointer));
    } on WarpException {
      rethrow;
    }

    from = did_from.toString();
    to = did_to.toString();

    final _friendRequestStatusNum =
        bindings.multipass_friend_request_status(pointer);

    final _friendRequestStatusMap = {
      0: FriendRequestStatusEnum.uninitialized,
      1: FriendRequestStatusEnum.pending,
      2: FriendRequestStatusEnum.accepted,
      3: FriendRequestStatusEnum.denied,
      4: FriendRequestStatusEnum.friendRemoved,
      5: FriendRequestStatusEnum.requestRemoved,
    };
    status = _friendRequestStatusMap[_friendRequestStatusNum]!;
    did_from.drop();
    did_to.drop();
    bindings.friendrequest_free(pointer);
  }
}

class MultiPass {
  Pointer<G_MultiPassAdapter> pointer;
  MultiPass(this.pointer);

  String createIdentity(String? username, String? passphrase) {
    Pointer<Char> pUsername =
        username != null ? username.toNativeUtf8().cast<Char>() : nullptr;

    Pointer<Char> pPassphrase =
        passphrase != null ? passphrase.toNativeUtf8().cast<Char>() : nullptr;

    G_FFIResult_DID result =
        bindings.multipass_create_identity(pointer, pUsername, pPassphrase);

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }

    if (pUsername != nullptr) {
      calloc.free(pUsername);
    }

    if (pPassphrase != nullptr) {
      calloc.free(pPassphrase);
    }

    DID did = DID(result.data);
    String didString = did.toString();
    did.drop();
    return didString;
  }

  List<Identity> getIdentity(Identifier identifier) {
    G_FFIResult_FFIVec_Identity result =
        bindings.multipass_get_identity(pointer, identifier.pointer());
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
    List<Identity> list = [];
    int length = result.data.ref.len;

    for (int i = 0; i < length; i++) {
      Pointer<G_Identity> pointer = result.data.ref.ptr.elementAt(i).value;
      Identity identity = Identity(pointer);
      list.add(identity);
    }

    return list;
  }

  List<Identity> getIdentityByUsername(String username) {
    Identifier identifier = Identifier.fromUserName(username);
    List<Identity> list;
    try {
      list = getIdentity(identifier);
    } on WarpException {
      rethrow;
    } finally {
      identifier.drop();
    }
    return list;
  }

  Identity getIdentityByDID(String did) {
    Identifier identifier = Identifier.fromDID(did);
    List<Identity> list;
    try {
      list = getIdentity(identifier);
    } on WarpException {
      rethrow;
    } finally {
      identifier.drop();
    }

    if (list.isEmpty) {
      throw Exception("Identity not found");
    }

    return list.first;
  }

  Identity getOwnIdentity() {
    G_FFIResult_Identity result = bindings.multipass_get_own_identity(pointer);
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
    return Identity(result.data);
  }

  void updateIdentity(IdentityUpdate option) {
    G_FFIResult_Null result =
        bindings.multipass_update_identity(pointer, option.pointer);
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
  }

  void refreshCache() {
    G_FFIResult_Null result = bindings.multipass_refresh_cache(pointer);
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
  }

  void sendFriendRequest(String key) {
    DID did;
    try {
      did = DID.fromString(key);
    } on WarpException {
      rethrow;
    }

    G_FFIResult_Null result =
        bindings.multipass_send_request(pointer, did.pointer);
    did.drop();

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
  }

  void acceptFriendRequest(String key) {
    DID did;
    try {
      did = DID.fromString(key);
    } on WarpException {
      rethrow;
    }
    G_FFIResult_Null result =
        bindings.multipass_accept_request(pointer, did.pointer);
    did.drop();
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
  }

  void denyFriendRequest(String key) {
    DID did;
    try {
      did = DID.fromString(key);
    } on WarpException {
      rethrow;
    }
    G_FFIResult_Null result =
        bindings.multipass_deny_request(pointer, did.pointer);
    did.drop();
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
  }

  void closeFriendRequest(String key) {
    DID did;
    try {
      did = DID.fromString(key);
    } on WarpException {
      rethrow;
    }
    G_FFIResult_Null result =
        bindings.multipass_close_request(pointer, did.pointer);
    did.drop();
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
  }

  bool receivedFriendRequestFrom(String key) {
    DID did;
    try {
      did = DID.fromString(key);
    } on WarpException {
      rethrow;
    }
    G_FFIResult_bool result =
        bindings.multipass_received_friend_request_from(pointer, did.pointer);
    did.drop();
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }

    bool received = result.data.cast<Int8>().value != 0;
    calloc.free(result.data);

    return received;
  }

  bool sentFriendRequestTo(String key) {
    DID did;
    try {
      did = DID.fromString(key);
    } on WarpException {
      rethrow;
    }
    G_FFIResult_bool result =
        bindings.multipass_sent_friend_request_to(pointer, did.pointer);
    did.drop();
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }

    bool sent = result.data.cast<Int8>().value != 0;
    calloc.free(result.data);

    return sent;
  }

  List<FriendRequest> listIncomingRequest() {
    G_FFIResult_FFIVec_FriendRequest result =
        bindings.multipass_list_incoming_request(pointer);
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
    List<FriendRequest> list = [];
    int length = result.data.ref.len;

    for (int i = 0; i < length; i++) {
      Pointer<G_FriendRequest> pointer = result.data.ref.ptr.elementAt(i).value;
      FriendRequest request = FriendRequest(pointer);
      list.add(request);
    }

    return list;
  }

  List<FriendRequest> listOutgoingRequest() {
    G_FFIResult_FFIVec_FriendRequest result =
        bindings.multipass_list_outgoing_request(pointer);
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
    List<FriendRequest> list = [];
    int length = result.data.ref.len;

    for (int i = 0; i < length; i++) {
      Pointer<G_FriendRequest> pointer = result.data.ref.ptr.elementAt(i).value;
      FriendRequest request = FriendRequest(pointer);
      list.add(request);
    }

    return list;
  }

  List<FriendRequest> listAllRequest() {
    G_FFIResult_FFIVec_FriendRequest result =
        bindings.multipass_list_all_request(pointer);
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
    List<FriendRequest> list = [];
    int length = result.data.ref.len;

    for (int i = 0; i < length; i++) {
      Pointer<G_FriendRequest> pointer = result.data.ref.ptr.elementAt(i).value;
      FriendRequest request = FriendRequest(pointer);
      list.add(request);
    }

    return list;
  }

  void removeFriend(String key) {
    DID did;
    try {
      did = DID.fromString(key);
    } on WarpException {
      rethrow;
    }
    G_FFIResult_Null result =
        bindings.multipass_remove_friend(pointer, did.pointer);
    did.drop();
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
  }

  void block(String key) {
    DID did;
    try {
      did = DID.fromString(key);
    } on WarpException {
      rethrow;
    }
    G_FFIResult_Null result = bindings.multipass_block(pointer, did.pointer);
    did.drop();
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
  }

  void unblock(String key) {
    DID did;
    try {
      did = DID.fromString(key);
    } on WarpException {
      rethrow;
    }
    G_FFIResult_Null result = bindings.multipass_unblock(pointer, did.pointer);
    did.drop();
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
  }

  bool isBlocked(String key) {
    DID did;
    try {
      did = DID.fromString(key);
    } on WarpException {
      rethrow;
    }
    G_FFIResult_bool result =
        bindings.multipass_is_blocked(pointer, did.pointer);
    did.drop();
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }

    bool blocked = result.data.cast<Int8>().value != 0;
    calloc.free(result.data);
    return blocked;
  }

  List<String> blockList() {
    G_FFIResult_FFIVec_DID result = bindings.multipass_block_list(pointer);
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
    List<String> list = [];
    int length = result.data.ref.len;

    for (int i = 0; i < length; i++) {
      Pointer<G_DID> pointer = result.data.ref.ptr.elementAt(i).value;
      DID key = DID(pointer);
      list.add(key.toString());
      key.drop();
    }

    return list;
  }

  List<String> listFriends() {
    G_FFIResult_FFIVec_DID result = bindings.multipass_list_friends(pointer);
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
    List<String> list = [];
    int length = result.data.ref.len;

    for (int i = 0; i < length; i++) {
      Pointer<G_DID> pointer = result.data.ref.ptr.elementAt(i).value;
      DID key = DID(pointer);
      list.add(key.toString());
      key.drop();
    }

    return list;
  }

  void hasFriend(String key) {
    DID did;
    try {
      did = DID.fromString(key);
    } on WarpException {
      rethrow;
    }
    G_FFIResult_Null result =
        bindings.multipass_has_friend(pointer, did.pointer);
    did.drop();
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
  }

  IdentityStatus identityStatus(String did) {
    DID didkey;

    try {
      didkey = DID.fromString(did);
    } on WarpException {
      rethrow;
    }

    G_FFIResult_IdentityStatus result =
        bindings.multipass_identity_status(pointer, didkey.pointer);
    didkey.drop();
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }

    late IdentityStatus status;
    final value = result.data.value;
    switch (value) {
      case 0:
        status = IdentityStatus.online;
        break;
      case 1:
        status = IdentityStatus.offline;
        break;
    }

    calloc.free(result.data);

    return status;
  }

  Relationship identityRelationship(String did) {
    DID didkey;

    try {
      didkey = DID.fromString(did);
    } on WarpException {
      rethrow;
    }
    G_FFIResult_Relationship result =
        bindings.multipass_identity_relationship(pointer, didkey.pointer);
    didkey.drop();

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
    return Relationship(result.data);
  }

  void drop() {
    bindings.multipassadapter_free(pointer);
  }
}

String? generateName() {
  Pointer<Char> ptr = bindings.multipass_generate_name();
  if (ptr == nullptr) {
    return null;
  }
  String name = ptr.cast<Utf8>().toDartString();
  calloc.free(ptr);
  return name;
}
