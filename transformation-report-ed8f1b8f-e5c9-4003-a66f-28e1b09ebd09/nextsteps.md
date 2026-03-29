# Next Steps

The solution has no build errors following the transformation. Below are steps to validate and deploy the project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to a supported cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If it still references a Windows-only TFM such as `net472` or `net48`, update it accordingly.

## 2. Review NuGet Package References

Check that all `<PackageReference>` entries in `AdoCore.csproj` resolve to versions that support the chosen TFM. Run the following command to restore and confirm there are no unresolved dependencies:

```bash
dotnet restore
```

Address any warnings about deprecated or incompatible packages that appear in the restore output.

## 3. Build the Solution

Perform a clean build to confirm the absence of errors in a fresh state:

```bash
dotnet build --configuration Release
```

Review the output for any warnings that may indicate runtime issues even if the build succeeds.

## 4. Run the Test Suite

If the solution contains test projects, execute them to verify that existing behavior is preserved after the transformation:

```bash
dotnet test --configuration Release
```

Review any failing tests and determine whether they are caused by API differences between .NET Framework and cross-platform .NET.

## 5. Check for Windows-Specific API Usage

Even when a project compiles successfully, it may reference APIs that are only functional on Windows. Use the .NET Compatibility Analyzer to surface these at build time by adding the following property to `AdoCore.csproj`:

```xml
<EnableNETAnalyzers>true</EnableNETAnalyzers>
<AnalysisMode>All</AnalysisMode>
```

Rebuild and address any `CA1416` platform compatibility warnings that appear.

## 6. Validate Runtime Behavior on Target Platforms

Run the application on each intended platform (Linux, macOS, Windows) to confirm consistent behavior:

```bash
dotnet run --configuration Release
```

Pay particular attention to file path handling, line endings, and any configuration or environment variable assumptions that may differ across operating systems.

## 7. Publish the Application

Once validation is complete, publish a self-contained or framework-dependent build for the target runtime. For example, to publish a self-contained binary for Linux x64:

```bash
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) for your deployment target. Verify the contents of the `./publish` output directory before deploying.