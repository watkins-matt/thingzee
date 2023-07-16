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
  } while (response.page! < (response.totalPages ?? 1));

  // Add the base url to all recipes
  final baseUrl = (client as _MealieApiClient).baseUrl;
  for (final recipe in allRecipes) {
    recipe.image = '$baseUrl${recipe.image}';
  }

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

@JsonSerializable(explicitToJson: true)
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
  List<MealieRecipeCategory>? recipeCategory;
  List<MealieRecipeTag>? tags;
  List<MealieRecipeTool>? tools;
  int? rating;
  String? orgURL;
  List<MealieRecipeIngredient>? recipeIngredient;
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

  factory MealieRecipe.fromJson(Map<String, dynamic> json) {
    json['image'] = '/api/media/recipes/${json['id']}/images/min-original.webp';
    return _$MealieRecipeFromJson(json);
  }

  Map<String, dynamic> toJson() => _$MealieRecipeToJson(this);
}

@JsonSerializable(explicitToJson: true)
class MealieRecipeCategory {
  String? id;
  String? name;
  String? slug;

  MealieRecipeCategory({
    this.id,
    this.name,
    this.slug,
  });

  factory MealieRecipeCategory.fromJson(Map<String, dynamic> json) =>
      _$MealieRecipeCategoryFromJson(json);
  Map<String, dynamic> toJson() => _$MealieRecipeCategoryToJson(this);
}

@JsonSerializable(explicitToJson: true)
class MealieRecipeIngredient {
  String? title;
  String? note;
  String? unit;
  String? food;
  bool? disableAmount;
  double? quantity;
  String? originalText;
  String? referenceId;

  MealieRecipeIngredient({
    this.title,
    this.note,
    this.unit,
    this.food,
    this.disableAmount,
    this.quantity,
    this.originalText,
    this.referenceId,
  });

  factory MealieRecipeIngredient.fromJson(Map<String, dynamic> json) =>
      _$MealieRecipeIngredientFromJson(json);
  Map<String, dynamic> toJson() => _$MealieRecipeIngredientToJson(this);
}

@JsonSerializable(explicitToJson: true)
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
      _$MealieRecipeResponseFromJson(json);
  Map<String, dynamic> toJson() => _$MealieRecipeResponseToJson(this);
}

@JsonSerializable(explicitToJson: true)
class MealieRecipeTag {
  String? id;
  String? name;
  String? slug;

  MealieRecipeTag({
    this.id,
    this.name,
    this.slug,
  });

  factory MealieRecipeTag.fromJson(Map<String, dynamic> json) => _$MealieRecipeTagFromJson(json);
  Map<String, dynamic> toJson() => _$MealieRecipeTagToJson(this);
}

@JsonSerializable(explicitToJson: true)
class MealieRecipeTool {
  String? id;
  String? name;
  String? slug;
  bool? onHand;

  MealieRecipeTool({
    this.id,
    this.name,
    this.slug,
    this.onHand,
  });

  factory MealieRecipeTool.fromJson(Map<String, dynamic> json) => _$MealieRecipeToolFromJson(json);
  Map<String, dynamic> toJson() => _$MealieRecipeToolToJson(this);
}
