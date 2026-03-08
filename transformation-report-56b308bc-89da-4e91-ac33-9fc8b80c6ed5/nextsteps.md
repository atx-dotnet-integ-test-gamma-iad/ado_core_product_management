# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are no warnings that could indicate deprecated APIs or compatibility issues that were not surfaced as errors.

## 3. Run Existing Tests

If a test project exists in the solution, execute the test suite to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Runtime-Only Issues

Some issues do not surface at build time but appear at runtime. Pay attention to the following areas:

- **Reflection-based code**: Behavior differences may exist between .NET Framework and modern .NET.
- **Configuration**: `System.Configuration.ConfigurationManager` requires the `System.Configuration.ConfigurationManager` NuGet package on cross-platform .NET. Verify any `app.config` or `web.config` usage has been accounted for.
- **Platform-specific APIs**: Any Windows-only APIs (e.g., registry access, COM interop, WCF) will throw `PlatformNotSupportedException` on non-Windows systems. Run the application on the target platform to confirm.
- **Globalization**: If the application relies on specific culture or encoding behavior, test with `Globalization Invariant Mode` disabled unless it was explicitly enabled.

## 5. Review NuGet Package Compatibility

Check that all NuGet packages referenced in `AdoCore.csproj` have versions that support the target framework. Use the following command to identify any outdated or incompatible packages:

```bash
dotnet list package --outdated
```

Update packages as needed using:

```bash
dotnet add package <PackageName> --version <LatestCompatibleVersion>
```

## 6. Run the Application

Execute the application directly to perform a basic smoke test:

```bash
dotnet run --configuration Release --project AdoCore.csproj
```

Verify that core functionality behaves as expected compared to the legacy version.

## 7. Publish the Application

Once validation is complete, publish the application for the target environment.

**Framework-dependent deployment** (requires .NET runtime on the target machine):

```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained deployment** (bundles the runtime, no installation required on target machine):

```bash
dotnet publish --configuration Release --self-contained true --runtime <RID> --output ./publish
```

Replace `<RID>` with the appropriate Runtime Identifier, for example:
- `win-x64` for Windows 64-bit
- `linux-x64` for Linux 64-bit
- `osx-x64` for macOS 64-bit

## 8. Verify Published Output

Navigate to the `./publish` directory and confirm the expected binaries and assets are present. Run the published output directly to confirm it functions correctly outside of the development environment:

```bash
./publish/AdoCore
```

Or on Windows:

```powershell
.\publish\AdoCore.exe
```