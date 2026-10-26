import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/inventory_repository.dart';
import '../../logic/catalog.dart';
import '../../logic/stock.dart';
import '../../models/item.dart';
import '../../providers/providers.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';
import 'product_list_page.dart';

/// New item when [item] is null, otherwise edit its details. Quantity is
/// only set here for a new item; after that it moves through stock in/out.
class ItemFormPage extends ConsumerStatefulWidget {
  const ItemFormPage({super.key, this.item});

  final Item? item;

  @override
  ConsumerState<ItemFormPage> createState() => _ItemFormPageState();
}

class _ItemFormPageState extends ConsumerState<ItemFormPage> {
  late final _name = TextEditingController(text: widget.item?.name);
  late final _code = TextEditingController(text: widget.item?.code);
  late final _unit = TextEditingController(text: widget.item?.unit ?? 'pcs');
  late final _price = TextEditingController(text: _num(widget.item?.price));
  late final _cost = TextEditingController(text: _num(widget.item?.cost));
  late final _lowAt =
      TextEditingController(text: '${widget.item?.lowStockAt ?? 2}');
  final _quantity = TextEditingController();
  late final _anime = TextEditingController(text: widget.item?.anime);
  late final _description =
      TextEditingController(text: widget.item?.description);
  late final _image = TextEditingController(text: widget.item?.imageUrl);
  final _animeFocus = FocusNode();
  late bool _listed = widget.item?.listed ?? false;
  late String _category = widget.item?.category ?? '';
  bool _busy = false;

  /// True while a photo is being saved.
  bool _savingPhoto = false;
  String? _error;

  static String _num(int? v) => v == null || v == 0 ? '' : '$v';

  @override
  void dispose() {
    for (final c in [
      _name,
      _code,
      _unit,
      _price,
      _cost,
      _lowAt,
      _quantity,
      _anime,
      _description,
      _image,
    ]) {
      c.dispose();
    }
    _animeFocus.dispose();
    super.dispose();
  }

  /// Empty means 0; anything else must be a whole number.
  int _read(TextEditingController c, String label) {
    if (c.text.trim().isEmpty) return 0;
    return parseWholeNumber(c.text) ??
        (throw InventoryException('$label must be a whole number.'));
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final draft = ItemDraft(
        name: _name.text,
        code: _code.text,
        unit: _unit.text,
        price: _read(_price, 'Selling price'),
        cost: _read(_cost, 'Cost price'),
        lowStockAt: _read(_lowAt, 'Low stock level'),
        listed: _listed,
        category: _category,
        anime: _anime.text,
        description: _description.text,
        imageUrl: _image.text,
      );
      final repo = ref.read(inventoryRepositoryProvider);
      final item = widget.item;
      if (item == null) {
        await repo.createItem(draft,
            initialQuantity: _read(_quantity, 'Starting quantity'));
      } else {
        await repo.updateItem(item.id, draft);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.item == null;
    const numberKeyboard = TextInputType.numberWithOptions();
    return Scaffold(
      appBar: AppBar(title: Text(isNew ? 'New item' : 'Edit item')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _photoField(),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            autofocus: isNew,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _code,
                  decoration: const InputDecoration(
                      labelText: 'Code (optional)', hintText: 'SKU / barcode'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _unit,
                  decoration: const InputDecoration(
                      labelText: 'Unit', hintText: 'pcs, box, kg'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _price,
                  keyboardType: numberKeyboard,
                  decoration: const InputDecoration(
                      labelText: 'Selling price', suffixText: 'Ks'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _cost,
                  keyboardType: numberKeyboard,
                  decoration: const InputDecoration(
                      labelText: 'Cost price', suffixText: 'Ks'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (isNew) ...[
                Expanded(
                  child: TextField(
                    controller: _quantity,
                    keyboardType: numberKeyboard,
                    decoration: const InputDecoration(
                        labelText: 'Starting quantity', hintText: '0'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: TextField(
                  controller: _lowAt,
                  keyboardType: numberKeyboard,
                  decoration:
                      const InputDecoration(labelText: 'Warn when at or below'),
                ),
              ),
            ],
          ),
          if (!isNew) ...[
            const SizedBox(height: 12),
            const Text(
              'To change the quantity, use In, Out or Count on the item page, '
              'so the history stays right.',
              style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
            ),
          ],
          const SizedBox(height: 20),
          _sellSection(),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.dangerInk)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy || _savingPhoto ? null : _save,
            child: Text(isNew ? 'Add item' : 'Save'),
          ),
        ],
      ),
    );
  }

  /// The item's photo: a big preview, then take, choose or remove. The
  /// photo is shrunk on the phone and uploaded at once; Save stores its
  /// address with the item.
  Widget _photoField() {
    return ValueListenableBuilder(
      valueListenable: _image,
      builder: (context, value, _) {
        final url = value.text.trim();
        final uploading = _savingPhoto;
        return Glass(
          radius: AppRadius.lg,
          shadow: false,
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 104,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      url.isEmpty
                          ? const ColoredBox(
                              color: AppColors.surfaceSunken,
                              child: Icon(Icons.add_a_photo_outlined,
                                  size: 32, color: AppColors.inkSubtle),
                            )
                          : ProductImage(url: url),
                      if (uploading)
                        ColoredBox(
                          color: Colors.white.withOpacity(0.7),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(url.isEmpty ? 'Add a photo' : 'Photo',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const Text(
                        'Customers see it in the shop. It is made smaller '
                        'before it is saved.',
                        style: TextStyle(
                            color: AppColors.inkMuted, fontSize: 12.5)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      children: [
                        TextButton.icon(
                          onPressed: uploading
                              ? null
                              : () => _pickPhoto(ImageSource.camera),
                          icon:
                              const Icon(Icons.photo_camera_outlined, size: 18),
                          label: const Text('Camera'),
                        ),
                        TextButton.icon(
                          onPressed: uploading
                              ? null
                              : () => _pickPhoto(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined,
                              size: 18),
                          label: const Text('Gallery'),
                        ),
                        if (url.isNotEmpty && !uploading)
                          TextButton(
                            onPressed: () => _image.clear(),
                            style: TextButton.styleFrom(
                                foregroundColor: AppColors.dangerInk),
                            child: const Text('Remove'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final photos = ref.read(photoRepositoryProvider);
    final shopId = ref.read(authStateProvider).valueOrNull?.uid;
    if (shopId == null) return;
    try {
      final picked = await photos.pick(source);
      if (picked == null || !mounted) return;
      setState(() {
        _savingPhoto = true;
        _error = null;
      });
      _image.text = await photos.save(shopId, picked);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _savingPhoto = false);
    }
  }

  /// Selling in the app: a switch, then what customers see and filter by.
  Widget _sellSection() {
    final animeNames = [
      for (final (name, _) in facet(
          ref.watch(productsProvider).valueOrNull ?? const [], (p) => p.anime))
        name,
    ];
    return Glass(
      radius: AppRadius.lg,
      shadow: false,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _listed,
            onChanged: (on) => setState(() => _listed = on),
            title: const Text('Sell in the app',
                style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(_listed
                ? 'Customers see it in the shop, with your shop name. '
                    'Its stock follows this item.'
                : 'Turn on to show it to customers in the app.'),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: AppMotion.settle,
            alignment: Alignment.topCenter,
            child: !_listed
                ? const SizedBox(width: double.infinity)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _category.isEmpty ? null : _category,
                        decoration:
                            const InputDecoration(labelText: 'Category'),
                        items: [
                          for (final c in productCategories)
                            DropdownMenuItem(value: c, child: Text(c)),
                        ],
                        onChanged: (c) => setState(() => _category = c ?? ''),
                      ),
                      const SizedBox(height: 12),
                      // Offers names already in the shop, so one series
                      // isn't spelled three ways.
                      RawAutocomplete<String>(
                        textEditingController: _anime,
                        focusNode: _animeFocus,
                        optionsBuilder: (value) {
                          final q = value.text.trim().toLowerCase();
                          if (q.isEmpty) return const [];
                          return animeNames.where((a) =>
                              a.toLowerCase().contains(q) &&
                              a.toLowerCase() != q);
                        },
                        fieldViewBuilder: (context, controller, focus, _) =>
                            TextField(
                          controller: controller,
                          focusNode: focus,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                              labelText: 'Anime', hintText: 'One Piece'),
                        ),
                        optionsViewBuilder: (context, onSelected, options) =>
                            Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 3,
                            color: const Color(0xF7FFFFFF),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                  maxHeight: 220, maxWidth: 320),
                              child: ListView(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                children: [
                                  for (final o in options)
                                    ListTile(
                                      dense: true,
                                      title: Text(o),
                                      onTap: () => onSelected(o),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _description,
                        minLines: 2,
                        maxLines: 5,
                        maxLength: maxTextLength,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Description (optional)',
                          hintText:
                              'Size, maker, condition, what is in the box',
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
