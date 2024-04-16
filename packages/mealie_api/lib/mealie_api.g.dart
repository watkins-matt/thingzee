// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mealie_api.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MealieRecipe _$MealieRecipeFromJson(Map<String, dynamic> json) => MealieRecipe(
      id: json['id'] as String?,
      userId: json['userId'] as String?,
      groupId: json['groupId'] as String?,
      name: json['name'] as String?,
      slug: json['slug'] as String?,
      image: json['image'] as String?,
      recipeYield: json['recipeYield'] as String?,
      totalTime: json['totalTime'] as String?,
      prepTime: json['prepTime'] as String?,
      cookTime: json['cookTime'] as String?,
      performTime: json['performTime'] as String?,
      description: json['description'] as String?,
      recipeCategory: (json['recipeCategory'] as List<dynamic>?)
          ?.map((e) => MealieRecipeCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
      tags: (json['tags'] as List<dynamic>?)
          ?.map((e) => MealieRecipeTag.fromJson(e as Map<String, dynamic>))
          .toList(),
      tools: (json['tools'] as List<dynamic>?)
          ?.map((e) => MealieRecipeTool.fromJson(e as Map<String, dynamic>))
          .toList(),
      rating: json['rating'] as num?,
      orgURL: json['orgURL'] as String?,
      recipeIngredient: (json['recipeIngredient'] as List<dynamic>?)
          ?.map(
              (e) => MealieRecipeIngredient.fromJson(e as Map<String, dynamic>))
          .toList(),
      dateAdded: json['dateAdded'] as String?,
      dateUpdated: json['dateUpdated'] as String?,
      createdAt: json['createdAt'] as String?,
      updateAt: json['updateAt'] as String?,
    );

Map<String, dynamic> _$MealieRecipeToJson(MealieRecipe instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'groupId': instance.groupId,
      'name': instance.name,
      'slug': instance.slug,
      'image': instance.image,
      'recipeYield': instance.recipeYield,
      'totalTime': instance.totalTime,
      'prepTime': instance.prepTime,
      'cookTime': instance.cookTime,
      'performTime': instance.performTime,
      'description': instance.description,
      'recipeCategory':
          instance.recipeCategory?.map((e) => e.toJson()).toList(),
      'tags': instance.tags?.map((e) => e.toJson()).toList(),
      'tools': instance.tools?.map((e) => e.toJson()).toList(),
      'rating': instance.rating,
      'orgURL': instance.orgURL,
      'recipeIngredient':
          instance.recipeIngredient?.map((e) => e.toJson()).toList(),
      'dateAdded': instance.dateAdded,
      'dateUpdated': instance.dateUpdated,
      'createdAt': instance.createdAt,
      'updateAt': instance.updateAt,
    };

MealieRecipeCategory _$MealieRecipeCategoryFromJson(
        Map<String, dynamic> json) =>
    MealieRecipeCategory(
      id: json['id'] as String?,
      name: json['name'] as String?,
      slug: json['slug'] as String?,
    );

Map<String, dynamic> _$MealieRecipeCategoryToJson(
        MealieRecipeCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'slug': instance.slug,
    };

MealieRecipeIngredient _$MealieRecipeIngredientFromJson(
        Map<String, dynamic> json) =>
    MealieRecipeIngredient(
      title: json['title'] as String?,
      note: json['note'] as String?,
      unit: json['unit'] as String?,
      food: json['food'] as String?,
      disableAmount: json['disableAmount'] as bool?,
      quantity: (json['quantity'] as num?)?.toDouble(),
      originalText: json['originalText'] as String?,
      referenceId: json['referenceId'] as String?,
    );

Map<String, dynamic> _$MealieRecipeIngredientToJson(
        MealieRecipeIngredient instance) =>
    <String, dynamic>{
      'title': instance.title,
      'note': instance.note,
      'unit': instance.unit,
      'food': instance.food,
      'disableAmount': instance.disableAmount,
      'quantity': instance.quantity,
      'originalText': instance.originalText,
      'referenceId': instance.referenceId,
    };

MealieRecipeResponse _$MealieRecipeResponseFromJson(
        Map<String, dynamic> json) =>
    MealieRecipeResponse(
      page: json['page'] as int?,
      perPage: json['perPage'] as int?,
      total: json['total'] as int?,
      totalPages: json['totalPages'] as int?,
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => MealieRecipe.fromJson(e as Map<String, dynamic>))
          .toList(),
      next: json['next'] as String?,
      previous: json['previous'] as String?,
    );

Map<String, dynamic> _$MealieRecipeResponseToJson(
        MealieRecipeResponse instance) =>
    <String, dynamic>{
      'page': instance.page,
      'perPage': instance.perPage,
      'total': instance.total,
      'totalPages': instance.totalPages,
      'items': instance.items?.map((e) => e.toJson()).toList(),
      'next': instance.next,
      'previous': instance.previous,
    };

MealieRecipeTag _$MealieRecipeTagFromJson(Map<String, dynamic> json) =>
    MealieRecipeTag(
      id: json['id'] as String?,
      name: json['name'] as String?,
      slug: json['slug'] as String?,
    );

Map<String, dynamic> _$MealieRecipeTagToJson(MealieRecipeTag instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'slug': instance.slug,
    };

MealieRecipeTool _$MealieRecipeToolFromJson(Map<String, dynamic> json) =>
    MealieRecipeTool(
      id: json['id'] as String?,
      name: json['name'] as String?,
      slug: json['slug'] as String?,
      onHand: json['onHand'] as bool?,
    );

Map<String, dynamic> _$MealieRecipeToolToJson(MealieRecipeTool instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'slug': instance.slug,
      'onHand': instance.onHand,
    };

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps,no_leading_underscores_for_local_identifiers

class _MealieApiClient implements MealieApiClient {
  _MealieApiClient(
    this._dio, {
    this.baseUrl,
  });

  final Dio _dio;

  String? baseUrl;

  @override
  Future<MealieRecipeResponse> getRecipes({
    List<String>? categories,
    List<String>? tags,
    List<String>? tools,
    List<String>? foods,
    String? groupId,
    int? page,
    int? perPage,
    String? orderBy,
    String? orderDirection,
    String? queryFilter,
    String? paginationSeed,
    String? cookbook,
    bool? requireAllCategories,
    bool? requireAllTags,
    bool? requireAllTools,
    bool? requireAllFoods,
    String? search,
    String? acceptLanguage,
  }) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'categories': categories,
      r'tags': tags,
      r'tools': tools,
      r'foods': foods,
      r'group_id': groupId,
      r'page': page,
      r'perPage': perPage,
      r'orderBy': orderBy,
      r'orderDirection': orderDirection,
      r'queryFilter': queryFilter,
      r'paginationSeed': paginationSeed,
      r'cookbook': cookbook,
      r'requireAllCategories': requireAllCategories,
      r'requireAllTags': requireAllTags,
      r'requireAllTools': requireAllTools,
      r'requireAllFoods': requireAllFoods,
      r'search': search,
    };
    queryParameters.removeWhere((k, v) => v == null);
    final _headers = <String, dynamic>{r'accept-language': acceptLanguage};
    _headers.removeWhere((k, v) => v == null);
    const Map<String, dynamic>? _data = null;
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<MealieRecipeResponse>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              '/api/recipes',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(
                baseUrl: _combineBaseUrls(
              _dio.options.baseUrl,
              baseUrl,
            ))));
    final value = MealieRecipeResponse.fromJson(_result.data!);
    return value;
  }

  RequestOptions _setStreamType<T>(RequestOptions requestOptions) {
    if (T != dynamic &&
        !(requestOptions.responseType == ResponseType.bytes ||
            requestOptions.responseType == ResponseType.stream)) {
      if (T == String) {
        requestOptions.responseType = ResponseType.plain;
      } else {
        requestOptions.responseType = ResponseType.json;
      }
    }
    return requestOptions;
  }

  String _combineBaseUrls(
    String dioBaseUrl,
    String? baseUrl,
  ) {
    if (baseUrl == null || baseUrl.trim().isEmpty) {
      return dioBaseUrl;
    }

    final url = Uri.parse(baseUrl);

    if (url.isAbsolute) {
      return url.toString();
    }

    return Uri.parse(dioBaseUrl).resolveUri(url).toString();
  }
}
