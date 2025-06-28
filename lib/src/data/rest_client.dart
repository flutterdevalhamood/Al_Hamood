import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:sample/src/constants/api_constants.dart';
import 'package:sample/src/models/user_model.dart';

part 'rest_client.g.dart';

var dio = Dio();
var restApi = RestClient(dio, baseUrl: apiEndPoint);

@RestApi(baseUrl: apiEndPoint)
abstract class RestClient {
  factory RestClient(Dio dio, {String baseUrl}) = _RestClient;

  @POST('/api/Login')
  Future<UserModel> login({
    @Field("email") String? email,
    @Field("password") String? password,
  });

  @POST('/api/Logout')
  Future<dynamic> logout({
    @Header("Authorization") String? token,
    @Field("id") int? id,
  });

  @POST('/api/UserChangePassword')
  Future<dynamic> changePassword({
    @Header("Authorization") String? token,
    @Field("currentPassword") String? currentPassword,
    @Field("password") String? password,
  });

  @GET('/api/TyreReplacement/paginate/{page}/{limit}')
  Future<dynamic> getTyreReplacement(
    @Path("page") int page,
    @Path("limit") int limit,
    @Header("Authorization") String? token,
  );

  @GET('/api/TyreReplacementDetail/{id}')
  Future<dynamic> getTyreReplacementDetail({
    @Path("id") int? id,
    @Header("Authorization") String? token,
  });

  @POST('/api/TyreReplacement')
  Future<dynamic> postTyreReplacement({
    @Header("Authorization") String? token,
    @Part(name: "company_vehicle_id") int? companyVehicleId,
    @Part(name: "vehicle_tyre_code_id") int? vehicleTyreCodeId,
    @Part(name: "supplier_id") int? supplierId,
    @Part(name: "brand") String? brand,
    @Part(name: "tyre_change_date") String? tyreChangeDate,
    @Part(name: "current_odometer") String? currentOdometer,
    @Part(name: "reason_for_change") String? reasonForChange,
    @Part(name: "changed_by") String? changedBy,
    @Part(name: 'odometer_image') List<MultipartFile>? files,
  });

  @GET('/api/getTyreReplacementBaseList')
  Future<dynamic> getTyreReplacementBaseList({
    @Header("Authorization") String? token,
  });

  @GET('/api/getTyreCodesOfVersion/{id}')
  Future<dynamic> getTyreCodeOfVersion({
    @Path("id") int? id,
    @Header("Authorization") String? token,
  });

  @POST('/api/TyreReplacementDelete')
  Future<dynamic> deleteTyreReplacement({
    @Header("Authorization") String? token,
    @Field("id") int? id,
    @Field("deleteDescription") String? description,
  });

  @POST('/api/TyreReplacementPictureUpload')
  Future<dynamic> postTyreReplacementPictureUpload({
    @Header("Authorization") String? token,
    @Part(name: "id") int? id,
    @Part(name: 'document[]') List<MultipartFile>? files,
  });

  @POST('/api/TyreReplacementPictureDeleteByID')
  Future<dynamic> deleteTyreReplacementPictureDelete({
    @Header("Authorization") String? token,
    @Field("id") int? id,
  });

  @GET('/api/SwapTyre/paginate/{page}/{limit}')
  Future<dynamic> getSwapTyre(
    @Path("page") int page,
    @Path("limit") int limit,
    @Header("Authorization") String? token,
  );

  @GET('/api/SwapTyreDetail/{id}')
  Future<dynamic> getSwapTyreDetail({
    @Path("id") int? id,
    @Header("Authorization") String? token,
  });

  @POST('/api/SwapTyre')
  Future<dynamic> postSwapTyre({
    @Header("Authorization") String? token,
    @Part(name: "from_company_vehicle_id") int? fromCompanyVehicleId,
    @Part(name: "from_vehicle_tyre_code_id") int? fromVehicleTyreCodeId,
    @Part(name: "from_tyre_depth_mm") String? fromTyreDepthMm,
    @Part(name: "from_tyre_condition") String? fromTyreCondition,
    @Part(name: "from_vehicle_odometer") String? fromVehicleOdometer,
    @Part(name: "from_vehicle_odometer_image")
    List<MultipartFile>? fromVehicleOdometerImage,
    @Part(name: "to_company_vehicle_id") int? toCompanyVehicleId,
    @Part(name: "to_vehicle_tyre_code_id") int? toVehicleTyreCodeId,
    @Part(name: "to_tyre_depth_mm") String? toTyreDepthMm,
    @Part(name: 'to_tyre_condition') String? toTyreCondition,
    @Part(name: 'to_vehicle_odometer') String? toVehicleOdometer,
    @Part(name: "to_vehicle_odometer_image")
    List<MultipartFile>? toVehicleOdometerImage,
    @Part(name: 'tyre_change_date') String? tyreChangeDate,
    @Part(name: 'reason_for_change') String? reasonForChange,
    @Part(name: 'changed_by') String? changedBy,
  });

  @GET('/api/getSwapTyreBaseList')
  Future<dynamic> getSwapTyreBaseList({@Header("Authorization") String? token});

  @GET('/api/getTyreCodesOfVersion/{id}')
  Future<dynamic> getSwapTyreCodeOfVersion({
    @Path("id") int? id,
    @Header("Authorization") String? token,
  });

  @POST('/api/SwapTyreDelete')
  Future<dynamic> deleteSwapTyreData({
    @Header("Authorization") String? token,
    @Field("id") int? id,
    @Field("deleteDescription") String? description,
  });

  @POST('/api/SwapTyrePictureUpload')
  Future<dynamic> postSwapTyrePictureUpload({
    @Header("Authorization") String? token,
    @Part(name: "id") int? id,
    @Part(name: 'document[]') List<MultipartFile>? files,
  });

  @POST('/api/SwapTyrePictureDeleteByID')
  Future<dynamic> deleteSwapTyrePictureDelete({
    @Header("Authorization") String? token,
    @Field("id") int? id,
  });
}
