# Next Steps

The solution has no build errors following the transformation. The steps below cover validation and deployment.

## 1. Review the Transformed Project File

Open `AdoCore.csproj` and confirm the following:

- The `<TargetFramework>` element targets a supported cross-platform .NET version, for example `net8.0`.
- Any remaining `<Reference>` elements that previously pointed to Windows-specific assemblies (e.g., `System.Data`, `System.Configuration`) have been replaced with the appropriate NuGet packages or framework references.
- No `<HintPath>` elements point to absolute paths or machine-specific locations.

## 2. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Resolve any warnings about deprecated or unlisted packages by updating them to their current stable versions using:

```bash
dotnet list package --outdated
dotnet add package <PackageName>
```

## 3. Build the Solution

Perform a clean build to confirm there are no lingering issues:

```bash
dotnet build --configuration Release
```

Review any warnings in the output. While warnings do not prevent a build, they can indicate compatibility issues that may surface at runtime.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Pay attention to any tests that fail or are skipped, as these may indicate areas where the migration introduced behavioral differences.

## 5. Verify Runtime Behavior on Target Platforms

Since the goal is cross-platform support, run and test the application on each intended platform (Windows, Linux, macOS) if possible:

```bash
dotnet run --configuration Release
```

Check for runtime exceptions related to:

- File path separators (`\` vs `/`)
- Platform-specific APIs that may not be available on non-Windows systems
- Registry access or Windows-specific interop calls
- Case-sensitive file systems on Linux

## 6. Check for Removed or Changed APIs

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any APIs used in the code that are not available in the target framework:

```bash
dotnet tool install -g dotnet-compatibility
```

Address any reported compatibility issues in the source code before proceeding.

## 7. Publish the Application

Once validation is complete, publish the application for the target runtime(s):

**Framework-dependent (requires .NET runtime on the target machine):**

```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (bundles the runtime with the application):**

```bash
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish/linux-x64
dotnet publish --configuration Release --self-contained true --runtime win-x64 --output ./publish/win-x64
```

Replace `linux-x64` or `win-x64` with the appropriate Runtime Identifier (RID) for your target environment. A full list of RIDs is available in the [.NET RID Catalog](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog).

## 8. Validate the Published Output

After publishing, run the output binary directly to confirm it executes correctly outside of the development environment:

```bash
./publish/AdoCore
```

Confirm that configuration files, static assets, and any required runtime dependencies are included in the published output directory.