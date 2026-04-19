import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/providers/child_provider.dart';
import '../../../../core/services/pet_service.dart';
import '../../../../core/widgets/animated_pet_widget.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../models/child_model.dart';
import '../../../../models/pet_model.dart';

class PetShopScreen extends StatefulWidget {
  const PetShopScreen({super.key});

  @override
  State<PetShopScreen> createState() => _PetShopScreenState();
}

class _PetShopScreenState extends State<PetShopScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<PetModel> _shopPets = [];
  List<ChildPetModel> _myPets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final child = context.read<ChildProvider>().activeChild!;
    final shop = await PetService.getAllPets();
    final mine = await PetService.getChildPets(child.id);
    if (mounted) {
      setState(() {
        _shopPets = shop;
        _myPets = mine;
        _isLoading = false;
      });
    }
  }

  Future<void> _buyPet(PetModel pet) async {
    final child = context.read<ChildProvider>().activeChild!;

    final owned = await PetService.childOwnsPet(child.id, pet.id);
    if (owned) {
      AppSnackbar.info(context, 'You already own ${pet.name}!');
      return;
    }

    if (child.coins < pet.price) {
      AppSnackbar.warning(context,
          'Not enough coins! Need ${pet.price - child.coins} more coins.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Buy ${pet.name}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedPetWidget(imageUrl: pet.imageUrl, size: 80),
            const SizedBox(height: 12),
            Text('This will cost ${pet.price} coins.'),
            Text('You have ${child.coins} coins.',
                style: const TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Buy!')),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await PetService.buyPet(
        childId: child.id,
        petId: pet.id,
        price: pet.price,
      );

      final updatedChild = ChildModel(
        id: child.id,
        parentId: child.parentId,
        nickname: child.nickname,
        avatarUrl: child.avatarUrl,
        coins: child.coins - pet.price,
        activePetId: child.activePetId,
      );
      if (mounted) {
        context.read<ChildProvider>().setActiveChild(updatedChild);
        AppSnackbar.success(context, '${pet.name} is now yours! 🎉');
        _load();
        _tabController.animateTo(1);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Purchase failed. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppTheme.petsColor,
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: const [
              Tab(text: 'Pet Shop'),
              Tab(text: 'My Pets'),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const LoadingWidget()
              : TabBarView(
            controller: _tabController,
            children: [_buildShop(), _buildMyPets()],
          ),
        ),
      ],
    );
  }

  Widget _buildShop() {
    if (_shopPets.isEmpty) {
      return const EmptyStateWidget(
          message: 'No pets in the shop yet.', icon: Icons.pets);
    }

    final child = context.watch<ChildProvider>().activeChild;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _shopPets.length,
      itemBuilder: (_, i) {
        final pet = _shopPets[i];
        final owned = _myPets.any((mp) => mp.petId == pet.id);
        final canAfford = (child?.coins ?? 0) >= pet.price;

        return GestureDetector(
          onTap: owned ? null : () => _buyPet(pet),
          child: Container(
            decoration: BoxDecoration(
              color: owned
                  ? AppTheme.success.withOpacity(0.1)
                  : AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: owned
                    ? AppTheme.success
                    : canAfford
                    ? AppTheme.petsColor.withOpacity(0.3)
                    : AppTheme.border,
                width: owned ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedPetWidget(imageUrl: pet.imageUrl, size: 80),
                const SizedBox(height: 8),
                Text(pet.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                if (owned)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Owned ✓',
                        style: TextStyle(
                            color: AppTheme.success,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: canAfford
                          ? AppTheme.accent.withOpacity(0.15)
                          : AppTheme.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.monetization_on,
                            color:
                            canAfford ? AppTheme.accent : AppTheme.danger,
                            size: 14),
                        const SizedBox(width: 4),
                        Text('${pet.price}',
                            style: TextStyle(
                                color: canAfford
                                    ? AppTheme.accent
                                    : AppTheme.danger,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMyPets() {
    if (_myPets.isEmpty) {
      return const EmptyStateWidget(
          message: 'You don\'t have any pets yet.\nVisit the shop!',
          icon: Icons.pets);
    }

    final child = context.watch<ChildProvider>().activeChild;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myPets.length,
      itemBuilder: (_, i) {
        final childPet = _myPets[i];
        final pet = childPet.pet;
        if (pet == null) return const SizedBox();
        final isActive = child?.activePetId == pet.id;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isActive
                ? const BorderSide(color: AppTheme.petsColor, width: 2)
                : BorderSide.none,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                AnimatedPetWidget(
                    imageUrl: pet.imageUrl,
                    soundUrl: pet.soundUrl,
                    size: 80,
                    animate: isActive),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(pet.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          if (isActive) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.petsColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text('Active',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.petsColor,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      if (pet.description != null) ...[
                        const SizedBox(height: 4),
                        Text(pet.description!,
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 13)),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        isActive
                            ? '🌟 Your active companion!'
                            : 'Tap "Set Active" to use this pet',
                        style: TextStyle(
                          fontSize: 12,
                          color: isActive
                              ? AppTheme.petsColor
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (!isActive)
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await PetService.setActivePet(
                          childId: child!.id,
                          petId: pet.id,
                        );
                        final updatedChild = ChildModel(
                          id: child.id,
                          parentId: child.parentId,
                          nickname: child.nickname,
                          avatarUrl: child.avatarUrl,
                          coins: child.coins,
                          activePetId: pet.id,
                        );
                        if (mounted) {
                          context
                              .read<ChildProvider>()
                              .setActiveChild(updatedChild);
                          AppSnackbar.success(context,
                              '${pet.name} is now your active companion!');
                          _load();
                        }
                      } catch (e) {
                        if (mounted) {
                          AppSnackbar.error(
                              context, 'Failed to set active pet.');
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.petsColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child:
                    const Text('Set Active', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}