import 'package:dio/dio.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:retrofit/retrofit.dart';

part 'mealie_api.g.dart';

Future<List<MealieRecipe>> fetchAllRecipes(MealieApiClient client) async {
  int page = 1;
  List<MealieRecipe> allRecipes = [];
  MealieRecipeResponse response;

  do {
    response = await client.getRecipes(page: page, perPage: 50);
    allRecipes.addAll(response.items ?? []);
    page++;
  } while (response.page! < response.totalPages!);

  return allRecipes;
}

@RestApi()
abstract class MealieApiClient {
  factory MealieApiClient(Dio dio, {String? baseUrl}) = _MealieApiClient;

  @GET('/api/recipes')
  Future<MealieRecipeResponse> getRecipes({
    @Query('categories') List<String>? categories,
    @Query('tags') List<String>? tags,
    @Query('tools') List<String>? tools,
    @Query('foods') List<String>? foods,
    @Query('group_id') String? groupId,
    @Query('page') int? page,
    @Query('perPage') int? perPage,
    @Query('orderBy') String? orderBy,
    @Query('orderDirection') String? orderDirection,
    @Query('queryFilter') String? queryFilter,
    @Query('paginationSeed') String? paginationSeed,
    @Query('cookbook') String? cookbook,
    @Query('requireAllCategories') bool? requireAllCategories,
    @Query('requireAllTags') bool? requireAllTags,
    @Query('requireAllTools') bool? requireAllTools,
    @Query('requireAllFoods') bool? requireAllFoods,
    @Query('search') String? search,
    @Header('accept-language') String? acceptLanguage,
  });
}

@JsonSerializable()
class MealieRecipe {
  String? id;
  String? userId;
  String? groupId;
  String? name;
  String? slug;
  String? image;
  String? recipeYield;
  String? totalTime;
  String? prepTime;
  String? cookTime;
  String? performTime;
  String? description;
  List<String>? recipeCategory;
  List<String>? tags;
  List<String>? tools;
  int? rating;
  String? orgURL;
  List<String>? recipeIngredient;
  String? dateAdded;
  String? dateUpdated;
  String? createdAt;
  String? updateAt;

  MealieRecipe({
    this.id,
    this.userId,
    this.groupId,
    this.name,
    this.slug,
    this.image,
    this.recipeYield,
    this.totalTime,
    this.prepTime,
    this.cookTime,
    this.performTime,
    this.description,
    this.recipeCategory,
    this.tags,
    this.tools,
    this.rating,
    this.orgURL,
    this.recipeIngredient,
    this.dateAdded,
    this.dateUpdated,
    this.createdAt,
    this.updateAt,
  });

  factory MealieRecipe.fromJson(Map<String, dynamic> json) => _$RecipeFromJson(json);
  Map<String, dynamic> toJson() => _$RecipeToJson(this);
}

@JsonSerializable()
class MealieRecipeResponse {
  int? page;
  int? perPage;
  int? total;
  int? totalPages;
  List<MealieRecipe>? items;
  String? next;
  String? previous;

  MealieRecipeResponse({
    this.page,
    this.perPage,
    this.total,
    this.totalPages,
    this.items,
    this.next,
    this.previous,
  });

  factory MealieRecipeResponse.fromJson(Map<String, dynamic> json) =>
      _$RecipeResponseFromJson(json);
  Map<String, dynamic> toJson() => _$RecipeResponseToJson(this);
}
