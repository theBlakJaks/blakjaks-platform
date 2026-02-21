package com.blakjaks.app.features.shop.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.ShoppingCart
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import coil.compose.AsyncImage
import com.blakjaks.app.core.components.BlakJaksCard
import com.blakjaks.app.core.components.GoldButton
import com.blakjaks.app.core.components.NicotineWarningBanner
import com.blakjaks.app.core.network.models.Product
import com.blakjaks.app.core.theme.*
import com.blakjaks.app.features.shop.CartViewModel
import com.blakjaks.app.features.shop.ShopViewModel
import org.koin.androidx.compose.koinViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ShopScreen(navController: NavController) {
    val shopViewModel: ShopViewModel = koinViewModel()
    val cartViewModel: CartViewModel = koinViewModel()

    val filteredProducts by shopViewModel.filteredProducts.collectAsState()
    val searchQuery by shopViewModel.searchQuery.collectAsState()
    val isLoading by shopViewModel.isLoading.collectAsState()
    val error by shopViewModel.error.collectAsState()
    val itemCount = cartViewModel.itemCount

    var selectedProduct by remember { mutableStateOf<Product?>(null) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(BackgroundPrimary)
    ) {
        // FDA-required nicotine warning banner — always at top
        NicotineWarningBanner()

        // Search bar
        OutlinedTextField(
            value = searchQuery,
            onValueChange = { shopViewModel.searchQuery.value = it },
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = Layout.screenMargin, vertical = Spacing.sm),
            placeholder = { Text("Search products...", color = TextDim) },
            leadingIcon = {
                Icon(Icons.Default.Search, contentDescription = "Search", tint = TextSecondary)
            },
            singleLine = true,
            shape = RoundedCornerShape(12.dp),
            colors = OutlinedTextFieldDefaults.colors(
                focusedBorderColor = Gold,
                unfocusedBorderColor = BorderColor,
                focusedTextColor = TextPrimary,
                unfocusedTextColor = TextPrimary,
                cursorColor = Gold,
                focusedContainerColor = BackgroundCard,
                unfocusedContainerColor = BackgroundCard
            )
        )

        Box(modifier = Modifier.weight(1f)) {
            when {
                isLoading && filteredProducts.isEmpty() -> {
                    // Loading shimmer grid
                    LoadingView()
                }
                error != null && filteredProducts.isEmpty() -> {
                    // Error state with retry
                    ErrorView(
                        message = error ?: "Unknown error",
                        onRetry = { shopViewModel.refresh() }
                    )
                }
                else -> {
                    LazyVerticalGrid(
                        columns = GridCells.Fixed(2),
                        contentPadding = PaddingValues(
                            horizontal = Layout.screenMargin,
                            vertical = Spacing.sm
                        ),
                        horizontalArrangement = Arrangement.spacedBy(Spacing.sm),
                        verticalArrangement = Arrangement.spacedBy(Spacing.sm),
                        modifier = Modifier.fillMaxSize()
                    ) {
                        items(filteredProducts) { product ->
                            ProductCard(
                                product = product,
                                onCardTap = { selectedProduct = product },
                                onAddToCart = { cartViewModel.addItem(product.id, 1) }
                            )
                        }
                    }
                }
            }
        }
    }

    // Cart FAB
    Box(
        modifier = Modifier
            .fillMaxSize()
            .padding(end = Spacing.lg, bottom = Spacing.lg),
        contentAlignment = Alignment.BottomEnd
    ) {
        Box {
            FloatingActionButton(
                onClick = { navController.navigate("cart") },
                containerColor = Gold,
                contentColor = Color.Black,
                shape = CircleShape
            ) {
                Icon(Icons.Default.ShoppingCart, contentDescription = "Cart")
            }

            // Badge
            if (itemCount > 0) {
                Box(
                    modifier = Modifier
                        .align(Alignment.TopEnd)
                        .size(20.dp)
                        .clip(CircleShape)
                        .background(Color.Red),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = if (itemCount > 9) "9+" else itemCount.toString(),
                        color = Color.White,
                        fontSize = 10.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
        }
    }

    // Product Detail Bottom Sheet
    selectedProduct?.let { product ->
        ProductDetailSheet(
            product = product,
            onDismiss = { selectedProduct = null },
            onAddToCart = { productId, quantity ->
                cartViewModel.addItem(productId, quantity)
                selectedProduct = null
            }
        )
    }
}

// ─── ProductCard ──────────────────────────────────────────────────────────────

@Composable
private fun ProductCard(
    product: Product,
    onCardTap: () -> Unit,
    onAddToCart: () -> Unit
) {
    BlakJaksCard(
        modifier = Modifier.clickable(onClick = onCardTap)
    ) {
        // Product image
        if (product.imageUrl != null) {
            AsyncImage(
                model = product.imageUrl,
                contentDescription = null,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(120.dp)
                    .clip(RoundedCornerShape(8.dp)),
                contentScale = ContentScale.Crop
            )
        } else {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(120.dp)
                    .clip(RoundedCornerShape(8.dp))
                    .background(BackgroundSurface),
                contentAlignment = Alignment.Center
            ) {
                Text("BJ", color = Gold, fontSize = 24.sp, fontWeight = FontWeight.Bold)
            }
        }

        Spacer(modifier = Modifier.height(Spacing.sm))

        // Product name
        Text(
            text = product.name,
            color = TextPrimary,
            fontSize = 13.sp,
            fontWeight = FontWeight.SemiBold,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis
        )

        // Flavor
        Text(
            text = product.flavor,
            color = TextSecondary,
            fontSize = 11.sp,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )

        Spacer(modifier = Modifier.height(Spacing.xs))

        // Price
        Text(
            text = "${"$%.2f".format(product.price)}",
            color = Gold,
            fontSize = 14.sp,
            fontWeight = FontWeight.Bold
        )

        Spacer(modifier = Modifier.height(Spacing.sm))

        // Add to Cart button
        Button(
            onClick = onAddToCart,
            modifier = Modifier
                .fillMaxWidth()
                .height(36.dp),
            enabled = product.inStock,
            shape = RoundedCornerShape(8.dp),
            colors = ButtonDefaults.buttonColors(
                containerColor = Gold,
                contentColor = Color.Black,
                disabledContainerColor = Gold.copy(alpha = 0.3f),
                disabledContentColor = Color.Black
            ),
            contentPadding = PaddingValues(horizontal = 8.dp, vertical = 0.dp)
        ) {
            Text(
                text = if (product.inStock) "Add to Cart" else "Out of Stock",
                fontSize = 11.sp,
                fontWeight = FontWeight.Bold
            )
        }
    }
}

// ─── LoadingView ──────────────────────────────────────────────────────────────

@Composable
private fun LoadingView() {
    LazyVerticalGrid(
        columns = GridCells.Fixed(2),
        contentPadding = PaddingValues(horizontal = Layout.screenMargin, vertical = Spacing.sm),
        horizontalArrangement = Arrangement.spacedBy(Spacing.sm),
        verticalArrangement = Arrangement.spacedBy(Spacing.sm),
        modifier = Modifier.fillMaxSize()
    ) {
        items(6) {
            BlakJaksCard {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(120.dp)
                        .background(BackgroundSurface)
                )
                Spacer(modifier = Modifier.height(Spacing.sm))
                Box(
                    modifier = Modifier
                        .fillMaxWidth(0.7f)
                        .height(14.dp)
                        .background(BackgroundSurface)
                )
                Spacer(modifier = Modifier.height(Spacing.xs))
                Box(
                    modifier = Modifier
                        .fillMaxWidth(0.5f)
                        .height(12.dp)
                        .background(BackgroundSurface)
                )
            }
        }
    }
}

// ─── ErrorView ────────────────────────────────────────────────────────────────

@Composable
private fun ErrorView(message: String, onRetry: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(Layout.screenMargin),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = "Something went wrong",
            color = TextPrimary,
            fontSize = 18.sp,
            fontWeight = FontWeight.Bold
        )
        Spacer(modifier = Modifier.height(Spacing.sm))
        Text(
            text = message,
            color = TextSecondary,
            fontSize = 14.sp
        )
        Spacer(modifier = Modifier.height(Spacing.lg))
        GoldButton(text = "Retry", onClick = onRetry, modifier = Modifier.width(160.dp))
    }
}
