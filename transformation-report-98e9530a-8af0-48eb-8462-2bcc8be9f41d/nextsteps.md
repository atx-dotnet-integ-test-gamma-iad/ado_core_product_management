# Next Steps

The solution has no build errors following the transformation. The steps below cover validation and deployment of the migrated project.

## 1. Review the Migrated Project File

Open `AdoCore.csproj` and confirm the following:

- The `<TargetFramework>` element targets a supported cross-platform .NET version, for example `net8.0`.
- Any remaining `<Reference>` elements that previously pointed to Windows-only assemblies (e.g., `System.Web`, `System.Windows.Forms`) have been replaced with appropriate NuGet packages or removed if no longer needed.
- `<PackageReference>` entries are present for any NuGet dependencies that were previously managed via `packages.config`.

## 2. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Resolve any warnings about deprecated or unlisted packages by updating to current stable versions via:

```bash
dotnet add package <PackageName>
```

## 3. Build the Solution

Perform a clean build to confirm there are no issues introduced after restore:

```bash
dotnet build --configuration Release
```

Review the output for any warnings that may indicate compatibility concerns, even if they do not block the build.

## 4. Run the Test Suite

If the solution contains test projects, execute them to verify that existing behavior is preserved:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` result files for any failing or skipped tests. Failing tests should be investigated before proceeding to deployment.

## 5. Validate Runtime Behavior

- Run the application locally on each target platform (Windows, Linux, macOS) if cross-platform support is a requirement.
- Exercise the primary code paths manually or through integration tests to confirm there are no runtime exceptions related to platform-specific APIs.
- Check for any calls to `Environment.OSVersion`, `Registry`, or other platform-specific APIs that may behave differently or throw on non-Windows systems.

## 6. Check for Nullable Reference Type Warnings

If the project has `<Nullable>enable</Nullable>` set, review compiler warnings related to nullability. These are not errors by default but can indicate potential null reference issues at runtime.

## 7. Review Output Artifacts

After a successful Release build, inspect the output directory (typically `bin/Release/net8.0/`) and confirm:

- The correct runtime assemblies are present.
- Any required configuration files (e.g., `appsettings.json`) are copied to the output directory.
- If a self-contained deployment is needed, publish with the appropriate runtime identifier:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier for your target environment (`win-x64`, `osx-x64`, etc.).

## 8. Publish the Application

For a framework-dependent deployment, run:

```bash
dotnet publish --configuration Release
```

The output will be placed in `bin/Release/net8.0/publish/`. Deploy the contents of this directory to the target environment, ensuring the correct .NET runtime version is installed on that machine.